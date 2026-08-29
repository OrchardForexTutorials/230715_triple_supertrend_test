/*
   Triple Supertrend Plus

   Copyright 2013-2023, Novateq Pty Ltd
   http://novateq.com.au

*/

#property strict

#ifndef app_version
#define app_version "1.00"

#define CExpert       CExpert_1_00
#define CExpertParent CExpertBase

// #define app_trial

#ifdef app_option_pro
#define inp input
#else
#define inp const
#endif

#endif

#define diag if ( InpUseDiagnostics )

#include <Novateq/Products/Triple Supertrend.mqh>

#include <Novateq/Frameworks/Framework_6.00/Licence/LicenceV2.mqh>

#include <Novateq/Frameworks/Framework_6.00/Common/CommonDefine.mqh>
#include <Novateq/Frameworks/Framework_6.00/Common/Functions/Functions.mqh>
#include <Novateq/Frameworks/Framework_6.00/Expert/ExpertBase.mqh>
#include <Novateq/Frameworks/Framework_6.00/Trade/TradeSetup.mqh>

#include <Novateq/Frameworks/Framework_6.00/Indicators/IndicatorSupertrend.mqh>
#include <Novateq/Frameworks/Framework_6.00/Indicators/IndicatorMA.mqh>
#include <Novateq/Frameworks/Framework_6.00/Indicators/IndicatorStochasticRSI.mqh>

enum ENUM_OPTION {
   OPTION_STANDARD,  // Standard
   OPTION_STOCH_RSI, // Trade Pro
   OPTION_EMA,       // EMA only
};

enum ENUM_STOCH_DIRECTION {
   STOCH_DIRECTION_NONE = -1,              // None
   STOCH_DIRECTION_BUY  = ORDER_TYPE_BUY,  // Buy
   STOCH_DIRECTION_SELL = ORDER_TYPE_SELL, // Sell
};
