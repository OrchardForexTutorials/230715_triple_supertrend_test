/*
   Stochastic RSI

   Copyright 2013-2023 Novateq Pty Ltd
   https://novateq.com.au

*/

#property strict

#include "Stochastic RSI.mqh"

#property copyright   app_copyright
#property link        app_link
#property version     app_version
#property description app_description

#property indicator_separate_window
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_buffers 4
#property indicator_plots 2
#property indicator_level1 20.0
#property indicator_level2 80.0
#property indicator_levelcolor clrSilver
#property indicator_levelstyle STYLE_DOT

//--- plot Main
#property indicator_label1 "K"
#property indicator_type1  DRAW_LINE
#property indicator_color1 clrBlue
#property indicator_style1 STYLE_SOLID
#property indicator_width1 1
//--- plot Signal
#property indicator_label2 "D"
#property indicator_type2  DRAW_LINE
#property indicator_color2 clrGreen
#property indicator_style2 STYLE_SOLID
#property indicator_width2 1
