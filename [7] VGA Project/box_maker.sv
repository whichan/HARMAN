`timescale 1ns / 1ps
// 프레임 첫행에 대해서만 이전 프레임 사용.
// box_maker v3: 픽셀 밀도 기반 박스 유지
//
// 박스 상태 머신 (박스당):
//   EMPTY   → [이번 프레임 pix_cnt >= CREATE_MIN] → ACTIVE
//   ACTIVE  → [이번 프레임 pix_cnt >= HOLD_MIN]   → ACTIVE  (좌표 업데이트)
//   ACTIVE  → [이번 프레임 pix_cnt <  HOLD_MIN]   → hold_cnt--
//           → [hold_cnt == 0]                      → EMPTY   (좌표 유지하다 소멸)
//
// CREATE_MIN > HOLD_MIN: 생성은 엄격, 유지는 느슨
// HOLD_MAX: 감지 안 될 때 몇 프레임까지 유지할지

module box_maker #(
    parameter IMG_W      = 320,
    parameter IMG_H      = 240,
    parameter NUM_BOXES  = 2,
    parameter MAX_BOX_W  = 160,
    parameter MAX_BOX_H  = 120,
    parameter CREATE_MIN = 300,   // 박스 생성 임계값 (엄격)
    parameter HOLD_MIN   = 80,    // 박스 유지 임계값 (느슨)
    parameter HOLD_MAX   = 5,     // 감지 끊겼을 때 유지 프레임 수
    parameter MAX_RUNS   = 4
) (
    input  logic       rclk,
    input  logic       reset,
    input  logic       vsync,
    input  logic       DE,
    input  logic [9:0] x_pixel,
    input  logic [9:0] y_pixel,
    input  logic       is_target,

    output logic [8:0] box_x_min [0:NUM_BOXES-1],
    output logic [8:0] box_x_max [0:NUM_BOXES-1],
    output logic [7:0] box_y_min [0:NUM_BOXES-1],
    output logic [7:0] box_y_max [0:NUM_BOXES-1],
    output logic       box_valid [0:NUM_BOXES-1]
);

    // ── 좌표 / 활성 영역 ──────────────────────────────────────────
    logic [8:0] cam_x;
    logic [7:0] cam_y;
    assign cam_x = x_pixel[8:0];
    assign cam_y = y_pixel[7:0];

    logic in_active;
    assign in_active = DE && (x_pixel < IMG_W) && (y_pixel < IMG_H);

    // ── 1클럭 지연 ───────────────────────────────────────────────
    logic       DE_d, in_active_d, is_target_d;
    logic [9:0] x_d, y_d;

    always_ff @(posedge rclk) begin
        DE_d        <= DE;
        x_d         <= x_pixel;
        y_d         <= y_pixel;
        is_target_d <= is_target;
        in_active_d <= in_active;
    end

    // ── 행 끝 / 프레임 끝 ────────────────────────────────────────
    logic row_end, frame_end;
    assign row_end   = DE_d && (x_d == IMG_W - 1) && (y_d <  IMG_H - 1);
    assign frame_end = DE_d && (x_d == IMG_W - 1) && (y_d == IMG_H - 1);

    // ── Run 타입 ──────────────────────────────────────────────────
    typedef struct packed {
        logic [8:0] x_start;
        logic [8:0] x_end;
        logic [1:0] box_id;
        logic       valid;
    } run_t;

    run_t cur_runs  [0:MAX_RUNS-1];
    run_t prev_runs [0:MAX_RUNS-1];
    logic [$clog2(MAX_RUNS+1)-1:0] cur_run_cnt;

    logic       in_run;
    logic [8:0] run_start_x;

    // ── 박스 추적 (프레임 내 임시 계산용) ────────────────────────
    logic [8:0]  bx_min  [0:NUM_BOXES-1];  // 이번 프레임 계산 중
    logic [8:0]  bx_max  [0:NUM_BOXES-1];
    logic [7:0]  by_min  [0:NUM_BOXES-1];
    logic [7:0]  by_max  [0:NUM_BOXES-1];
    logic [15:0] pix_cnt [0:NUM_BOXES-1];  // 이번 프레임 픽셀 수
    logic        bactive [0:NUM_BOXES-1];  // 이번 프레임에 run이 걸렸나
    logic [1:0]  next_box_id;

    // ── 박스 유지 상태 ────────────────────────────────────────────
    // box_valid/x_min 등은 출력 레지스터 = 실제 표시되는 박스
    // hold_cnt: 0이면 EMPTY, >0이면 ACTIVE
    logic [$clog2(HOLD_MAX+1):0] hold_cnt [0:NUM_BOXES-1];

    // ── vsync 에지 ────────────────────────────────────────────────
    logic vsync_d, frame_start;
    always_ff @(posedge rclk) vsync_d <= vsync;
    assign frame_start = vsync && !vsync_d;

    // ── run 종료 감지 ─────────────────────────────────────────────
    logic run_fell, run_rowend;
    assign run_fell   = in_active_d && is_target_d && in_active && !is_target;
    assign run_rowend = row_end && in_run;

    logic [8:0] run_end_x;
    assign run_end_x = run_rowend ? (IMG_W[8:0] - 1) : (x_d[8:0] - 1);

    integer i, k;

    always_ff @(posedge rclk) begin
        if (reset) begin
            // 완전 리셋
            for (i = 0; i < MAX_RUNS; i++) begin
                cur_runs[i]  <= '{x_start:'0, x_end:'0, box_id:'0, valid:1'b0};
                prev_runs[i] <= '{x_start:'0, x_end:'0, box_id:'0, valid:1'b0};
            end
            for (i = 0; i < NUM_BOXES; i++) begin
                bx_min[i]    <= 9'd319; bx_max[i]    <= 9'd0;
                by_min[i]    <= 8'd239; by_max[i]    <= 8'd0;
                pix_cnt[i]   <= '0;
                bactive[i]   <= 1'b0;
                hold_cnt[i]  <= '0;
                box_valid[i] <= 1'b0;
                box_x_min[i] <= '0; box_x_max[i] <= '0;
                box_y_min[i] <= '0; box_y_max[i] <= '0;
            end
            cur_run_cnt <= '0;
            in_run      <= 1'b0;
            run_start_x <= '0;
            next_box_id <= '0;

        end else begin

            // ── frame_start: 프레임 내 임시 계산용만 리셋 ────────
            // 출력 레지스터(box_valid, box_x_min 등)는 건드리지 않음!
            if (frame_start) begin
                for (i = 0; i < MAX_RUNS; i++) begin
                    cur_runs[i]  <= '{x_start:'0, x_end:'0, box_id:'0, valid:1'b0};
                    prev_runs[i] <= '{x_start:'0, x_end:'0, box_id:'0, valid:1'b0};
                end
                for (i = 0; i < NUM_BOXES; i++) begin
                    bx_min[i]  <= 9'd319; bx_max[i]  <= 9'd0;
                    by_min[i]  <= 8'd239; by_max[i]  <= 8'd0;
                    pix_cnt[i] <= '0;
                    bactive[i] <= 1'b0;
                end
                cur_run_cnt <= '0;
                in_run      <= 1'b0;
                run_start_x <= '0;
                next_box_id <= '0;
            end

            // ── 1. run 시작/종료 추적 ────────────────────────────
            if (in_active) begin
                if (is_target && !in_run) begin
                    in_run      <= 1'b1;
                    run_start_x <= cam_x;
                end
            end
            if (row_end || frame_end || !in_active) begin
                if (in_active || in_active_d) in_run <= 1'b0;
            end
            if (run_fell) in_run <= 1'b0;

            // ── 2. run 완성 → 박스 매칭 ──────────────────────────
            if (run_fell || run_rowend) begin : run_process
                logic [8:0] rx_s, rx_e;
                logic        matched;
                logic [1:0]  mid;

                rx_s    = run_start_x;
                rx_e    = run_end_x;
                matched = 1'b0;
                mid     = 2'd0;

                // prev_runs와 x범위 겹침 검사
                for (k = 0; k < MAX_RUNS; k++) begin
                    if (prev_runs[k].valid && !matched) begin
                        if (!(rx_e < prev_runs[k].x_start) &&
                            !(rx_s > prev_runs[k].x_end)) begin
                            matched = 1'b1;
                            mid     = prev_runs[k].box_id;
                        end
                    end
                end

                // 폴백 1: 현재 프레임 누적 bx_min/bx_max와 겹치면 연결
                if (!matched) begin
                    for (k = 0; k < NUM_BOXES; k++) begin
                        if (hold_cnt[k] > 0 && bactive[k] && !matched) begin
                            if (!(rx_e < bx_min[k]) &&
                                !(rx_s > bx_max[k])) begin
                                matched = 1'b1;
                                mid     = k[1:0];
                            end
                        end
                    end
                end

                // 폴백 2: 현재 프레임 누적 없으면 이전 프레임 box_x_min/max로
                if (!matched) begin
                    for (k = 0; k < NUM_BOXES; k++) begin
                        if (hold_cnt[k] > 0 && !matched) begin
                            if (!(rx_e < box_x_min[k]) &&
                                !(rx_s > box_x_max[k])) begin
                                matched = 1'b1;
                                mid     = k[1:0];
                            end
                        end
                    end
                end

                if (matched) begin
                    if (cur_run_cnt < MAX_RUNS) begin
                        cur_runs[cur_run_cnt] <= '{x_start:rx_s, x_end:rx_e,
                                                   box_id:mid, valid:1'b1};
                        cur_run_cnt <= cur_run_cnt + 1;
                    end
                    if (rx_s < bx_min[mid]) bx_min[mid] <= rx_s;
                    if (rx_e > bx_max[mid]) bx_max[mid] <= rx_e;
                    if (run_rowend) begin
                        if (y_d[7:0] < by_min[mid]) by_min[mid] <= y_d[7:0];
                        if (y_d[7:0] > by_max[mid]) by_max[mid] <= y_d[7:0];
                    end else begin
                        if (cam_y < by_min[mid]) by_min[mid] <= cam_y;
                        if (cam_y > by_max[mid]) by_max[mid] <= cam_y;
                    end
                    pix_cnt[mid] <= pix_cnt[mid] + (rx_e - rx_s + 1);
                    bactive[mid] <= 1'b1;
                    // 크기 초과 검사는 frame_end에서만 수행
                    // (run 단위 검사 시 by_max 타이밍 오판으로 오작동)

                end else if (next_box_id < NUM_BOXES) begin
                    // 슬롯이 비어있을 때만 새 박스 할당
                    if (hold_cnt[next_box_id] == 0) begin
                        if (cur_run_cnt < MAX_RUNS) begin
                            cur_runs[cur_run_cnt] <= '{x_start:rx_s, x_end:rx_e,
                                                       box_id:next_box_id, valid:1'b1};
                            cur_run_cnt <= cur_run_cnt + 1;
                        end
                        bx_min[next_box_id]  <= rx_s;
                        bx_max[next_box_id]  <= rx_e;
                        by_min[next_box_id]  <= run_rowend ? y_d[7:0] : cam_y;
                        by_max[next_box_id]  <= run_rowend ? y_d[7:0] : cam_y;
                        pix_cnt[next_box_id] <= rx_e - rx_s + 1;
                        bactive[next_box_id] <= 1'b1;
                        next_box_id          <= next_box_id + 1;
                    end else begin
                        // 슬롯이 사용 중이면 다음 슬롯 시도
                        next_box_id <= next_box_id + 1;
                    end
                end
            end

            // ── 3. 행 끝: prev_runs 교체 ─────────────────────────
            if (row_end) begin
                for (i = 0; i < MAX_RUNS; i++) begin
                    prev_runs[i] <= cur_runs[i];
                    cur_runs[i]  <= '{x_start:'0, x_end:'0, box_id:'0, valid:1'b0};
                end
                cur_run_cnt <= '0;
            end

            // ── 4. 프레임 끝: 밀도 기반 박스 유지/소멸/생성 ──────
            if (frame_end) begin
                for (i = 0; i < NUM_BOXES; i++) begin

                    // 크기 초과 → 이번 프레임 무효 (frame_end에서 한 번만 검사)
                    if ((bx_max[i] - bx_min[i]) > MAX_BOX_W ||
                        (by_max[i] - by_min[i]) > MAX_BOX_H) begin
                        bactive[i] <= 1'b0;
                    end

                    if (hold_cnt[i] == 0) begin
                        // ── EMPTY 상태: 생성 조건 검사 ───────────
                        if (pix_cnt[i] >= CREATE_MIN && bactive[i]) begin
                            box_x_min[i] <= bx_min[i];
                            box_x_max[i] <= bx_max[i];
                            box_y_min[i] <= by_min[i];
                            box_y_max[i] <= by_max[i];
                            box_valid[i] <= 1'b1;
                            hold_cnt[i]  <= HOLD_MAX;
                        end

                    end else begin
                        // ── ACTIVE 상태: 유지 조건 검사 ──────────
                        if (pix_cnt[i] >= HOLD_MIN && bactive[i]) begin
                            box_x_min[i] <= bx_min[i];
                            box_x_max[i] <= bx_max[i];
                            box_y_min[i] <= by_min[i];
                            box_y_max[i] <= by_max[i];
                            box_valid[i] <= 1'b1;
                            hold_cnt[i]  <= HOLD_MAX;
                        end else begin
                            // 픽셀 부족 → 좌표 유지, 카운터 감소
                            hold_cnt[i] <= hold_cnt[i] - 1;
                            if (hold_cnt[i] == 1) begin
                                // 다음 클럭에 0이 됨 → 박스 소멸
                                box_valid[i] <= 1'b0;
                            end
                            // box_x_min 등은 건드리지 않음 (좌표 유지)
                        end
                    end

                end

                // 다음 프레임을 위한 run 리셋
                next_box_id <= '0;
                for (i = 0; i < MAX_RUNS; i++) begin
                    cur_runs[i]  <= '{x_start:'0, x_end:'0, box_id:'0, valid:1'b0};
                    prev_runs[i] <= '{x_start:'0, x_end:'0, box_id:'0, valid:1'b0};
                end
            end

        end
    end

endmodule

// // box가 중앙을 지나갈때 할당 초기화됨.
// // box를 생성 후 유지하는 로직
// `timescale 1ns / 1ps

// // box_maker v3: 픽셀 밀도 기반 박스 유지
// //
// // 박스 상태 머신 (박스당):
// //   EMPTY   → [이번 프레임 pix_cnt >= CREATE_MIN] → ACTIVE
// //   ACTIVE  → [이번 프레임 pix_cnt >= HOLD_MIN]   → ACTIVE  (좌표 업데이트)
// //   ACTIVE  → [이번 프레임 pix_cnt <  HOLD_MIN]   → hold_cnt--
// //           → [hold_cnt == 0]                      → EMPTY   (좌표 유지하다 소멸)
// //
// // CREATE_MIN > HOLD_MIN: 생성은 엄격, 유지는 느슨
// // HOLD_MAX: 감지 안 될 때 몇 프레임까지 유지할지

// module box_maker #(
//     parameter IMG_W      = 320,
//     parameter IMG_H      = 240,
//     parameter NUM_BOXES  = 2,
//     parameter MAX_BOX_W  = 160,
//     parameter MAX_BOX_H  = 120,
//     parameter CREATE_MIN = 300,   // 박스 생성 임계값 (엄격)
//     parameter HOLD_MIN   = 80,    // 박스 유지 임계값 (느슨)
//     parameter HOLD_MAX   = 5,     // 감지 끊겼을 때 유지 프레임 수
//     parameter MAX_RUNS   = 4
// ) (
//     input  logic       rclk,
//     input  logic       reset,
//     input  logic       vsync,
//     input  logic       DE,
//     input  logic [9:0] x_pixel,
//     input  logic [9:0] y_pixel,
//     input  logic       is_target,

//     output logic [8:0] box_x_min [0:NUM_BOXES-1],
//     output logic [8:0] box_x_max [0:NUM_BOXES-1],
//     output logic [7:0] box_y_min [0:NUM_BOXES-1],
//     output logic [7:0] box_y_max [0:NUM_BOXES-1],
//     output logic       box_valid [0:NUM_BOXES-1]
// );

//     // ── 좌표 / 활성 영역 ──────────────────────────────────────────
//     logic [8:0] cam_x;
//     logic [7:0] cam_y;
//     assign cam_x = x_pixel[8:0];
//     assign cam_y = y_pixel[7:0];

//     logic in_active;
//     assign in_active = DE && (x_pixel < IMG_W) && (y_pixel < IMG_H);

//     // ── 1클럭 지연 ───────────────────────────────────────────────
//     logic       DE_d, in_active_d, is_target_d;
//     logic [9:0] x_d, y_d;

//     always_ff @(posedge rclk) begin
//         DE_d        <= DE;
//         x_d         <= x_pixel;
//         y_d         <= y_pixel;
//         is_target_d <= is_target;
//         in_active_d <= in_active;
//     end

//     // ── 행 끝 / 프레임 끝 ────────────────────────────────────────
//     logic row_end, frame_end;
//     assign row_end   = DE_d && (x_d == IMG_W - 1) && (y_d <  IMG_H - 1);
//     assign frame_end = DE_d && (x_d == IMG_W - 1) && (y_d == IMG_H - 1);

//     // ── Run 타입 ──────────────────────────────────────────────────
//     typedef struct packed {
//         logic [8:0] x_start;
//         logic [8:0] x_end;
//         logic [1:0] box_id;
//         logic       valid;
//     } run_t;

//     run_t cur_runs  [0:MAX_RUNS-1];
//     run_t prev_runs [0:MAX_RUNS-1];
//     logic [$clog2(MAX_RUNS+1)-1:0] cur_run_cnt;

//     logic       in_run;
//     logic [8:0] run_start_x;

//     // ── 박스 추적 (프레임 내 임시 계산용) ────────────────────────
//     logic [8:0]  bx_min  [0:NUM_BOXES-1];  // 이번 프레임 계산 중
//     logic [8:0]  bx_max  [0:NUM_BOXES-1];
//     logic [7:0]  by_min  [0:NUM_BOXES-1];
//     logic [7:0]  by_max  [0:NUM_BOXES-1];
//     logic [15:0] pix_cnt [0:NUM_BOXES-1];  // 이번 프레임 픽셀 수
//     logic        bactive [0:NUM_BOXES-1];  // 이번 프레임에 run이 걸렸나
//     logic [1:0]  next_box_id;

//     // ── 박스 유지 상태 ────────────────────────────────────────────
//     // box_valid/x_min 등은 출력 레지스터 = 실제 표시되는 박스
//     // hold_cnt: 0이면 EMPTY, >0이면 ACTIVE
//     logic [$clog2(HOLD_MAX+1):0] hold_cnt [0:NUM_BOXES-1];

//     // ── vsync 에지 ────────────────────────────────────────────────
//     logic vsync_d, frame_start;
//     always_ff @(posedge rclk) vsync_d <= vsync;
//     assign frame_start = vsync && !vsync_d;

//     // ── run 종료 감지 ─────────────────────────────────────────────
//     logic run_fell, run_rowend;
//     assign run_fell   = in_active_d && is_target_d && in_active && !is_target;
//     assign run_rowend = row_end && in_run;

//     logic [8:0] run_end_x;
//     assign run_end_x = run_rowend ? (IMG_W[8:0] - 1) : (x_d[8:0] - 1);

//     integer i, k;

//     always_ff @(posedge rclk) begin
//         if (reset) begin
//             // 완전 리셋
//             for (i = 0; i < MAX_RUNS; i++) begin
//                 cur_runs[i]  <= '{x_start:'0, x_end:'0, box_id:'0, valid:1'b0};
//                 prev_runs[i] <= '{x_start:'0, x_end:'0, box_id:'0, valid:1'b0};
//             end
//             for (i = 0; i < NUM_BOXES; i++) begin
//                 bx_min[i]    <= 9'd319; bx_max[i]    <= 9'd0;
//                 by_min[i]    <= 8'd239; by_max[i]    <= 8'd0;
//                 pix_cnt[i]   <= '0;
//                 bactive[i]   <= 1'b0;
//                 hold_cnt[i]  <= '0;
//                 box_valid[i] <= 1'b0;
//                 box_x_min[i] <= '0; box_x_max[i] <= '0;
//                 box_y_min[i] <= '0; box_y_max[i] <= '0;
//             end
//             cur_run_cnt <= '0;
//             in_run      <= 1'b0;
//             run_start_x <= '0;
//             next_box_id <= '0;

//         end else begin

//             // ── frame_start: 프레임 내 임시 계산용만 리셋 ────────
//             // 출력 레지스터(box_valid, box_x_min 등)는 건드리지 않음!
//             if (frame_start) begin
//                 for (i = 0; i < MAX_RUNS; i++) begin
//                     cur_runs[i]  <= '{x_start:'0, x_end:'0, box_id:'0, valid:1'b0};
//                     prev_runs[i] <= '{x_start:'0, x_end:'0, box_id:'0, valid:1'b0};
//                 end
//                 for (i = 0; i < NUM_BOXES; i++) begin
//                     bx_min[i]  <= 9'd319; bx_max[i]  <= 9'd0;
//                     by_min[i]  <= 8'd239; by_max[i]  <= 8'd0;
//                     pix_cnt[i] <= '0;
//                     bactive[i] <= 1'b0;
//                 end
//                 cur_run_cnt <= '0;
//                 in_run      <= 1'b0;
//                 run_start_x <= '0;
//                 next_box_id <= '0;
//             end

//             // ── 1. run 시작/종료 추적 ────────────────────────────
//             if (in_active) begin
//                 if (is_target && !in_run) begin
//                     in_run      <= 1'b1;
//                     run_start_x <= cam_x;
//                 end
//             end
//             if (row_end || frame_end || !in_active) begin
//                 if (in_active || in_active_d) in_run <= 1'b0;
//             end
//             if (run_fell) in_run <= 1'b0;

//             // ── 2. run 완성 → 박스 매칭 ──────────────────────────
//             if (run_fell || run_rowend) begin : run_process
//                 logic [8:0] rx_s, rx_e;
//                 logic        matched;
//                 logic [1:0]  mid;

//                 rx_s    = run_start_x;
//                 rx_e    = run_end_x;
//                 matched = 1'b0;
//                 mid     = 2'd0;

//                 // prev_runs와 x범위 겹침 검사
//                 for (k = 0; k < MAX_RUNS; k++) begin
//                     if (prev_runs[k].valid && !matched) begin
//                         if (!(rx_e < prev_runs[k].x_start) &&
//                             !(rx_s > prev_runs[k].x_end)) begin
//                             matched = 1'b1;
//                             mid     = prev_runs[k].box_id;
//                         end
//                     end
//                 end

//                 // 매칭 실패 시: ACTIVE 박스(hold_cnt>0)의 x범위와 겹치면 연결
//                 if (!matched) begin
//                     for (k = 0; k < NUM_BOXES; k++) begin
//                         if (hold_cnt[k] > 0 && !matched) begin
//                             if (!(rx_e < box_x_min[k]) &&
//                                 !(rx_s > box_x_max[k])) begin
//                                 matched = 1'b1;
//                                 mid     = k[1:0];
//                             end
//                         end
//                     end
//                 end

//                 if (matched) begin
//                     if (cur_run_cnt < MAX_RUNS) begin
//                         cur_runs[cur_run_cnt] <= '{x_start:rx_s, x_end:rx_e,
//                                                    box_id:mid, valid:1'b1};
//                         cur_run_cnt <= cur_run_cnt + 1;
//                     end
//                     if (rx_s < bx_min[mid]) bx_min[mid] <= rx_s;
//                     if (rx_e > bx_max[mid]) bx_max[mid] <= rx_e;
//                     if (run_rowend) begin
//                         if (y_d[7:0] < by_min[mid]) by_min[mid] <= y_d[7:0];
//                         if (y_d[7:0] > by_max[mid]) by_max[mid] <= y_d[7:0];
//                     end else begin
//                         if (cam_y < by_min[mid]) by_min[mid] <= cam_y;
//                         if (cam_y > by_max[mid]) by_max[mid] <= cam_y;
//                     end
//                     pix_cnt[mid] <= pix_cnt[mid] + (rx_e - rx_s + 1);
//                     bactive[mid] <= 1'b1;

//                     // 크기 초과 → 이번 프레임 계산 무효화
//                     if ((bx_max[mid] - bx_min[mid]) > MAX_BOX_W ||
//                         (by_max[mid] - by_min[mid]) > MAX_BOX_H) begin
//                         bactive[mid] <= 1'b0;
//                         bx_min[mid] <= 9'd319; bx_max[mid] <= 9'd0;
//                         by_min[mid] <= 8'd239; by_max[mid] <= 8'd0;
//                         pix_cnt[mid] <= '0;
//                     end

//                 end else if (next_box_id < NUM_BOXES) begin
//                     // 슬롯이 비어있을 때만 새 박스 할당
//                     if (hold_cnt[next_box_id] == 0) begin
//                         if (cur_run_cnt < MAX_RUNS) begin
//                             cur_runs[cur_run_cnt] <= '{x_start:rx_s, x_end:rx_e,
//                                                        box_id:next_box_id, valid:1'b1};
//                             cur_run_cnt <= cur_run_cnt + 1;
//                         end
//                         bx_min[next_box_id]  <= rx_s;
//                         bx_max[next_box_id]  <= rx_e;
//                         by_min[next_box_id]  <= run_rowend ? y_d[7:0] : cam_y;
//                         by_max[next_box_id]  <= run_rowend ? y_d[7:0] : cam_y;
//                         pix_cnt[next_box_id] <= rx_e - rx_s + 1;
//                         bactive[next_box_id] <= 1'b1;
//                         next_box_id          <= next_box_id + 1;
//                     end else begin
//                         // 슬롯이 사용 중이면 다음 슬롯 시도
//                         next_box_id <= next_box_id + 1;
//                     end
//                 end
//             end

//             // ── 3. 행 끝: prev_runs 교체 ─────────────────────────
//             if (row_end) begin
//                 for (i = 0; i < MAX_RUNS; i++) begin
//                     prev_runs[i] <= cur_runs[i];
//                     cur_runs[i]  <= '{x_start:'0, x_end:'0, box_id:'0, valid:1'b0};
//                 end
//                 cur_run_cnt <= '0;
//             end

//             // ── 4. 프레임 끝: 밀도 기반 박스 유지/소멸/생성 ──────
//             if (frame_end) begin
//                 for (i = 0; i < NUM_BOXES; i++) begin

//                     if (hold_cnt[i] == 0) begin
//                         // ── EMPTY 상태: 생성 조건 검사 ───────────
//                         if (pix_cnt[i] >= CREATE_MIN && bactive[i]) begin
//                             // 박스 생성!
//                             box_x_min[i] <= bx_min[i];
//                             box_x_max[i] <= bx_max[i];
//                             box_y_min[i] <= by_min[i];
//                             box_y_max[i] <= by_max[i];
//                             box_valid[i] <= 1'b1;
//                             hold_cnt[i]  <= HOLD_MAX;
//                         end
//                         // 생성 조건 미달 → 계속 EMPTY, 출력 유지 안 함

//                     end else begin
//                         // ── ACTIVE 상태: 유지 조건 검사 ──────────
//                         if (pix_cnt[i] >= HOLD_MIN && bactive[i]) begin
//                             // 충분한 픽셀 감지 → 좌표 업데이트 + hold 리셋
//                             box_x_min[i] <= bx_min[i];
//                             box_x_max[i] <= bx_max[i];
//                             box_y_min[i] <= by_min[i];
//                             box_y_max[i] <= by_max[i];
//                             box_valid[i] <= 1'b1;
//                             hold_cnt[i]  <= HOLD_MAX;  // 카운터 리셋
//                         end else begin
//                             // 픽셀 부족 → 좌표 유지, 카운터 감소
//                             hold_cnt[i] <= hold_cnt[i] - 1;
//                             if (hold_cnt[i] == 1) begin
//                                 // 다음 클럭에 0이 됨 → 박스 소멸
//                                 box_valid[i] <= 1'b0;
//                             end
//                             // box_x_min 등은 건드리지 않음 (좌표 유지)
//                         end
//                     end

//                 end

//                 // 다음 프레임을 위한 run 리셋
//                 next_box_id <= '0;
//                 for (i = 0; i < MAX_RUNS; i++) begin
//                     cur_runs[i]  <= '{x_start:'0, x_end:'0, box_id:'0, valid:1'b0};
//                     prev_runs[i] <= '{x_start:'0, x_end:'0, box_id:'0, valid:1'b0};
//                 end
//             end

//         end
//     end

// endmodule
