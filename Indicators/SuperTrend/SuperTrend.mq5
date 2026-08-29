/*
   SuperTrend.mq5
   Copyright 2013-2023, Novateq Pty Ltd
   https://www.novateq.com.au

   Description: SuperTrend Indicator

*/

// Indicator properties
#property copyright "Copyright 2013-2021, Novateq Pty Ltd"
#property link "https://orchardforex.com"

#property indicator_chart_window

#property indicator_buffers 3
#property indicator_plots 2

// Upper line properties
#property indicator_label1 "Upper"
#property indicator_color1 clrYellow
#property indicator_style1 STYLE_SOLID
#property indicator_type1  DRAW_LINE
#property indicator_width1 2

// Lower line properties
#property indicator_label2 "Lower"
#property indicator_color2 clrGreen
#property indicator_style2 STYLE_SOLID
#property indicator_type2  DRAW_LINE
#property indicator_width2 2

#property indicator_label3 "ST"
#property indicator_type3 DRAW_NONE

// Constant definitions
#define INDICATOR_NAME    "SuperTrend"
#define INDICATOR_VERSION "v1.04, www.novateq.com.au"

enum ENUM_PRICE_MODE {
   PRICE_MODE_HIGHLOW,   // High/Low
   PRICE_MODE_OPENCLOSE, // Open/Close
};

// Indicator parameters
input int             InpPeriod     = 20;  // Period
input double          InpMultiplier = 2.0; // ATR Multiplier
input ENUM_PRICE_MODE InpPriceMode  = PRICE_MODE_HIGHLOW;

// Buffers
double                BufferUpper[];
double                BufferLower[];
double                BufferSuperTrend[];

//	Handles
int                   HandleMA;
int                   HandleATR;

double                ValuesMA[];
double                ValuesATR[];

int                   OnInit() {

   int index = 0;
   AssignIndexBuffer( index, BufferUpper, INDICATOR_DATA );
   AssignIndexBuffer( index, BufferLower, INDICATOR_DATA );
   AssignIndexBuffer( index, BufferSuperTrend, INDICATOR_DATA );

   HandleATR = iATR( Symbol(), Period(), InpPeriod );
   HandleMA  = iMA( Symbol(), Period(), InpPeriod, 0, MODE_SMA, PRICE_CLOSE );
   if ( HandleATR == INVALID_HANDLE || HandleMA == INVALID_HANDLE ) {
      PrintFormat( "Could not create indicator for %i periods", InpPeriod );
      return ( INIT_FAILED );
   }

   ArraySetAsSeries( ValuesATR, true );
   ArraySetAsSeries( ValuesMA, true );

   return ( INIT_SUCCEEDED );
}

int OnCalculate( const int       rates_total,     //
                 const int       prev_calculated, //
                 const datetime &time[],          //
                 const double   &open[],          //
                 const double   &high[],          //
                 const double   &low[],           //
                 const double   &close[],         //
                 const long     &tick_volume[],   //
                 const long     &volume[],        //
                 const int      &spread[] ) {

   if ( IsStopped() ) return ( 0 );

   if ( rates_total < InpPeriod ) return ( 0 );

   int atrCalculated = BarsCalculated( HandleATR );
   int maCalculated  = BarsCalculated( HandleMA );
   if ( atrCalculated < rates_total || maCalculated < rates_total ) {
      Print( "waiting on calculations" );
      return ( 0 );
   }

   int count;
   if ( prev_calculated > rates_total || prev_calculated < 0 ) {
      count = rates_total;
   }
   else {
      count = rates_total - prev_calculated;
      if ( prev_calculated > 0 ) count++;
   }

   if ( CopyBuffer( HandleATR, 0, 0, count, ValuesATR ) < count ) {
      Print( "Getting ATR failed! Error ", GetLastError() );
      return ( 0 );
   }

   if ( CopyBuffer( HandleMA, 0, 0, count, ValuesMA ) < count ) {
      Print( "Getting MA failed! Error ", GetLastError() );
      return ( 0 );
   }

   ArraySetAsSeries( high, true );
   ArraySetAsSeries( low, true );
   ArraySetAsSeries( open, true );
   ArraySetAsSeries( close, true );

   for ( int i = count - 1; i >= 0 && !IsStopped(); i-- ) {

      // Calc SuperTrend
      double atr   = ValuesATR[i];
      double matr  = atr * InpMultiplier;
      double mid   = ( ( InpPriceMode == PRICE_MODE_HIGHLOW ) ? ( high[i] + low[i] ) : ( open[i] + close[i] ) ) / 2;
      double upper = mid + matr;
      double lower = mid - matr;

      if ( i >= ( rates_total - 1 ) ) {
         BufferUpper[i]      = upper;
         BufferLower[i]      = EMPTY_VALUE;
         BufferSuperTrend[i] = BufferUpper[i];
         continue;
      }

      CalculateTrend( i, upper, lower, close, BufferUpper, BufferLower, BufferSuperTrend );
   }

   return ( rates_total );
}

void CalculateTrend( int index, double upper, double lower, const double &close[], double &upperBuffer[], double &lowerBuffer[], double &mainBuffer[] ) {

   int prev           = index + 1;
   upperBuffer[index] = EMPTY_VALUE;
   lowerBuffer[index] = EMPTY_VALUE;

   if ( lowerBuffer[prev] == EMPTY_VALUE && ( close[index] > mainBuffer[prev] || close[index] > upper ) ) {
      // Closed above the upper trend line
      mainBuffer[index]  = lower;
      lowerBuffer[index] = lower;
   }
   else if ( upperBuffer[prev] == EMPTY_VALUE && ( close[index] < mainBuffer[prev] || close[index] < lower ) ) {
      //	Closed below the lower trend line
      mainBuffer[index]  = upper;
      upperBuffer[index] = upper;
   }
   else if ( mainBuffer[prev] < lower ) {
      //	Move lower trend line up
      mainBuffer[index]  = lower;
      lowerBuffer[index] = lower;
   }
   else if ( mainBuffer[prev] > upper ) {
      //	Move upper trend line down
      mainBuffer[index]  = upper;
      upperBuffer[index] = upper;
   }
   else {
      //	Keep all trend lines at previous level
      //	established trend lines cannot move further away
      mainBuffer[index]  = mainBuffer[prev];
      lowerBuffer[index] = lowerBuffer[prev];
      upperBuffer[index] = upperBuffer[prev];
   }

   return;
}

void AssignIndexBuffer( int &index, double &buffer[], ENUM_INDEXBUFFER_TYPE type = INDICATOR_DATA ) {

   SetIndexBuffer( index++, buffer, type );
   ArraySetAsSeries( buffer, true );
}

//+------------------------------------------------------------------+
