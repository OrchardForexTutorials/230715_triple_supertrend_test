/*
   Stochastic RSI

   Copyright 2013-2023 Novateq Pty Ltd
   https://novateq.com.au

*/

#property strict

#define app_version     "1.04"
#define app_copyright   "Copyright 2013-2022, Novateq Pty Ltd"
#define app_link        "https://novateq.com.au"
#define app_author      "Novateq Pty Ltd"
#define app_description "Stochastic RSI /|\\\\"
#define app_icon        "Resources/icon.ico"

input int                InpKPeriod          = 3;           // K
input int                InpDPeriod          = 3;           // D
input int                InpRSIPeriod        = 14;          // RSI Period
input int                InpStochasticPeriod = 14;          // Stochastic Period
input ENUM_APPLIED_PRICE InpRSIAppliedPrice  = PRICE_CLOSE; // RSI Applied Price

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
double                   KBuffer[];
double                   DBuffer[];
double                   RSIBuffer[];
double                   StochBuffer[];
int                      RSIHandle;

;
int OnInit() {

   IndicatorSetInteger( INDICATOR_DIGITS, _Digits );
   //--- indicator buffers mapping
   SetIndexBuffer( 0, KBuffer, INDICATOR_DATA );
   SetIndexBuffer( 1, DBuffer, INDICATOR_DATA );
   SetIndexBuffer( 2, RSIBuffer, INDICATOR_CALCULATIONS );
   SetIndexBuffer( 3, StochBuffer, INDICATOR_CALCULATIONS );

   //--- getting RSI handle
   RSIHandle = iRSI( _Symbol, _Period, InpRSIPeriod, InpRSIAppliedPrice );
   //--- setting the arrays in timeseries
   ArraySetAsSeries( KBuffer, true );
   ArraySetAsSeries( DBuffer, true );
   ArraySetAsSeries( RSIBuffer, true );
   ArraySetAsSeries( StochBuffer, true );
   //---
   return ( INIT_SUCCEEDED );
}

int OnCalculate( const int rates_total, const int prev_calculated, const datetime &time[], const double &open[], const double &high[], const double &low[], const double &close[],
                 const long &tick_volume[], const long &volume[], const int &spread[] ) {
   //---

   int calculated = BarsCalculated( RSIHandle );
   if ( calculated < rates_total ) {
      Print( "Not all data of RSIHandle is calculated (", calculated, "bars ). Error", GetLastError() );
      return ( 0 );
   }

   int to_copy;
   if ( prev_calculated > rates_total || prev_calculated < 0 )
      to_copy = rates_total;
   else {
      to_copy = rates_total - prev_calculated;
      if ( prev_calculated > 0 ) to_copy++;
   }
   if ( IsStopped() ) return ( 0 ); // Checking for stop flag

   if ( CopyBuffer( RSIHandle, 0, 0, to_copy, RSIBuffer ) <= 0 ) {
      Print( "Getting RSIBuffer is failed! Error", GetLastError() );
      return ( 0 );
   }

   int limit = prev_calculated == 0 ? rates_total - ( InpRSIPeriod + 1 ) : rates_total - prev_calculated + 1;
   for ( int i = limit; i >= 0; i-- ) {
      if ( i < rates_total - ( InpRSIPeriod + 2 ) ) StochBuffer[i] = Stoch( RSIBuffer, RSIBuffer, RSIBuffer, InpStochasticPeriod, i, rates_total );
      if ( StochBuffer[i + InpKPeriod - 1] != EMPTY_VALUE ) KBuffer[i] = SimpleMA( i, InpKPeriod, StochBuffer, rates_total );
      if ( KBuffer[i + InpDPeriod - 1] != EMPTY_VALUE ) DBuffer[i] = SimpleMA( i, InpDPeriod, KBuffer, rates_total );
   }
   //--- return value of prev_calculated for next call
   return ( rates_total );
}

double Stoch( const double &source[], double &high[], double &low[], int length, int shift, const int &rates_total ) {
   if ( shift + length > rates_total ) return EMPTY_VALUE;
   double Highest = Highest( high, length, shift );
   double Lowest  = Lowest( low, length, shift );
   if ( Highest - Lowest == 0 ) return EMPTY_VALUE;
   return 100 * ( source[shift] - Lowest ) / ( Highest - Lowest );
}

double Lowest( double &low[], int length, int shift ) {
   double Result = 0;
   for ( int i = shift; i <= shift + length; i++ ) {
      if ( Result == 0 || ( low[i] < Result && low[i] != EMPTY_VALUE ) ) {
         Result = low[i];
      }
   }

   return Result;
}

double Highest( double &high[], int length, int shift ) {
   double Result = 0;
   for ( int i = shift; i <= shift + length; i++ ) {
      if ( Result == 0 || ( high[i] > Result && high[i] != EMPTY_VALUE ) ) {
         Result = high[i];
      }
   }

   return Result;
}

double SimpleMA( const int position, const int period, const double &price[], const int &rates_total ) {
   //---
   double result = 0.0;
   if ( position <= rates_total - period && period > 0 ) {
      for ( int i = 0; i < period; i++ ) {
         if ( price[position + i] != EMPTY_VALUE ) {
            result += price[position + i];
         }
      }
      result /= period;
   }
   return ( result );
}
//+------------------------------------------------------------------+
