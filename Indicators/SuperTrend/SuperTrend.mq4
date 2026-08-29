/*
   SuperTrend.mq4
   Copyright 2013-2021, Novateq Pty Ltd
   https://www.novateq.com.au

   Description: SuperTrend Indicator

*/

// Indicator properties
#property copyright "Copyright 2013-2021, Novateq Pty Ltd"
#property link "https://www.novateq.com.au"

#property indicator_chart_window

#property indicator_buffers 3
#property indicator_plots 3 //	Not essential for MQL4

#property indicator_color1 Yellow
#property indicator_width1 1
#property indicator_type1  DRAW_NONE

#property indicator_color2 FireBrick
#property indicator_width2 2

#property indicator_color3 Green
#property indicator_width3 2

// Constant definitions
#define INDICATOR_NAME "SuperTrend"

// Indicator parameters
input int    InpPeriod     = 10;  // SuperTrend ATR Period
input double InpMultiplier = 1.7; // SuperTrend Multiplier

#include "../Include/CSR.mqh"

int OnInit() {

   Init();

   return ( INIT_SUCCEEDED );
}

int OnCalculate( const int rates_total, const int prev_calculated, const datetime &time[], const double &open[], const double &high[], const double &low[], const double &close[],
                 const long &tick_volume[], const long &volume[], const int &spread[] ) {

   //	Need a minimum number of available rates to function
   if ( rates_total < InpPeriod ) return ( 0 );

   //	Housekeeping to release asap
   if ( IsStopped() ) return ( 0 );

   // Skip values already calculated
   int start = ( prev_calculated == 0 ) ? rates_total - InpPeriod - 1 : rates_total - prev_calculated;

   //	Loop through bars
   for ( int i = start; i >= 0 && !IsStopped(); i-- ) {

      // Calc SuperTrend
      double atr   = iATR( Symbol(), Period(), InpPeriod, i );
      double matr  = atr * InpMultiplier;
      double upper = ( ( high[i] + low[i] ) / 2 ) + matr;
      double lower = ( ( high[i] + low[i] ) / 2 ) - matr;

      CalculateTrend( i, upper, lower, close );
   }

   return ( rates_total );
}

//+------------------------------------------------------------------+
