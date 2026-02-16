
#ifndef SRC_AP_APMAIN_H_
#define SRC_AP_APMAIN_H_

#include "../driver/Button/button.h"
#include "../driver/Led/Led.h"
#include "../HAL/sys_timer/sys_timer.h"
#include "../HAL/FND/fnd.h"

void App_Init();
void App_Clock_Run();
void App_Stopwatch_Run();
void App_Button_Check();
void App_Display_FND();
void App_Excute();

#define BTN_U 0
#define BTN_L 1
#define BTN_R 2
#define BTN_D 3
#endif /* SRC_AP_APMAIN_H_ */
