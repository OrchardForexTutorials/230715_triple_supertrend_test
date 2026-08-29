/*
   Triple Supertrend Plus

   Copyright 2013-2023, Novateq Pty Ltd
   http://novateq.com.au

   No new trade while a trade is open
*/

#property strict

#include "Defines.mqh"

//
//	Inputs
//

input ENUM_OPTION      InpOption           = OPTION_STANDARD; // Strategy option

inp int                InpST1Period        = 10;                 // Supertrend 1 Period
inp double             InpST1Multiplier    = 1.0;                // Supertrend 1 ATR Multiplier
inp ENUM_PRICE_MODE    InpST1PriceMode     = PRICE_MODE_HIGHLOW; // Supertrend 1 Price Mode

inp int                InpST2Period        = 11;                 // Supertrend 2 Period
inp double             InpST2Multiplier    = 2.0;                // Supertrend 2 ATR Multiplier
inp ENUM_PRICE_MODE    InpST2PriceMode     = PRICE_MODE_HIGHLOW; // Supertrend 2 Price Mode

inp int                InpST3Period        = 12;                 // Supertrend 3 Period
inp double             InpST3Multiplier    = 3.0;                // Supertrend 3 ATR Multiplier
inp ENUM_PRICE_MODE    InpST3PriceMode     = PRICE_MODE_HIGHLOW; // Supertrend 3 Price Mode

inp int                InpMAPeriod         = 200;         // MA Period
inp ENUM_MA_METHOD     InpMAMethod         = MODE_EMA;    // MA Method
inp ENUM_APPLIED_PRICE InpMAAppliedPrice   = PRICE_CLOSE; // MA Applied Price

inp int                InpSRSIKPeriod      = 3;           // Stochastic RSI K Period
inp int                InpSRSIDPeriod      = 3;           // Stochastic RSI D Period
inp int                InpSRSIRSIPeriod    = 14;          // Stochastic RSI RSI Period
inp int                InpSRSIPeriod       = 14;          // Stochastic RSI Period
inp ENUM_APPLIED_PRICE InpSRSIAppliedPrice = PRICE_CLOSE; // Stochastic RSI Applied Price
inp double             InpSRSIOverbought   = 80;          // Stochastic overbought
inp double             InpSRSIOversold     = 20;          // Stochastic oversold

inp double             InpTPSLRatio        = 1.5; // Take profit stop loss ratio

//	Basic info
input double           InpVolume           = 0.01;        // Trade volume
input int              InpMagic            = app_magic;   // Magic number
input string           InpTradeComment     = app_comment; // Trade comment

#define CParent CExpertBase
#define CClass  CExpert

class CClass : public CParent {

protected:
   CIndicatorSupertrend    *mSupertrend1;
   CIndicatorSupertrend    *mSupertrend2;
   CIndicatorSupertrend    *mSupertrend3;
   CIndicatorMA            *mMA;
   CIndicatorStochasticRSI *mStochR;

   ENUM_STOCH_DIRECTION     mStochDirection;

   void                     RunStandard();
   void                     RunEma();
   void                     RunStochRSI();
   int                      TestSupertrend( int index );

   bool                     PositionOpen( ENUM_ORDER_TYPE type, double slPrice, double tpRatio );

   //   bool CloseAll( ENUM_POSITION_TYPE type );
   //   bool CloseAtSL( ENUM_POSITION_TYPE type, double currentPrice );
   //   bool CloseNett( ENUM_POSITION_TYPE type );
   //   bool DeleteOrders( int type );
   //   bool ClosePositions( ENUM_POSITION_TYPE type );
   //
   //   bool OpenOrder( ENUM_ORDER_TYPE type, double price );

public:
   CClass();
   ~CClass();

   virtual bool On_Tick( bool firstTime, bool newBar );
};

CClass::CClass() : CParent( Symbol(), InpMagic, InpTradeComment ) {

   mSupertrend1    = new CIndicatorSupertrend( InpST1Period, InpST1Multiplier, InpST1PriceMode );
   mSupertrend2    = new CIndicatorSupertrend( InpST2Period, InpST2Multiplier, InpST2PriceMode );
   mSupertrend3    = new CIndicatorSupertrend( InpST3Period, InpST3Multiplier, InpST3PriceMode );
   mMA             = new CIndicatorMA( InpMAPeriod, InpMAMethod, InpMAAppliedPrice );
   mStochR         = new CIndicatorStochasticRSI( InpSRSIKPeriod, InpSRSIDPeriod, InpSRSIRSIPeriod, InpSRSIPeriod, InpSRSIAppliedPrice );

   mStochDirection = STOCH_DIRECTION_NONE;
}

CClass::~CClass() {
   delete mSupertrend1;
   delete mSupertrend2;
   delete mSupertrend3;
   delete mMA;
   delete mStochR;
}

bool CClass::On_Tick( bool firstTime, bool newBar ) {

   if ( !newBar ) return true;

   mSupertrend1.FillBuffers( 0, 4 );
   mSupertrend2.FillBuffers( 0, 4 );
   mSupertrend3.FillBuffers( 0, 4 );
   mMA.FillBuffers( 0, 4 );
   mStochR.FillBuffers( 0, 4 );

   switch ( InpOption ) {
      case OPTION_STANDARD:
         RunStandard();
         break;
      case OPTION_STOCH_RSI:
         RunStochRSI();
         break;
      case OPTION_EMA:
         RunEma();
         break;
   }

   return true;
}

void CClass::RunEma() {

   if ( PositionInfo.Count( mSymbol, InpMagic ) > 0 ) return; // no double trading

   double close   = iClose( mSymbol, mTimeframe, 1 );
   int    trend   = TestSupertrend( 1 );
   double slPrice = 0;

   // Buy Trade
   if ( close > mMA.Main( 1 ) ) {
      if ( trend >= 2 ) {
         if ( mSupertrend1.Lower( 1 ) != EMPTY_VALUE && mSupertrend2.Lower( 1 ) != EMPTY_VALUE ) {
            slPrice = mSupertrend2.Lower( 1 );
         }
         else {
            slPrice = mSupertrend3.Lower( 1 );
         }
         PositionOpen( ORDER_TYPE_BUY, slPrice, InpTPSLRatio );
      }
   }

   // Sell trade
   if ( close < mMA.Main( 1 ) ) {
      if ( trend <= -2 ) {
         if ( mSupertrend1.Upper( 1 ) != EMPTY_VALUE && mSupertrend2.Upper( 1 ) != EMPTY_VALUE ) {
            slPrice = mSupertrend2.Upper( 1 );
         }
         else {
            slPrice = mSupertrend3.Upper( 1 );
         }
         PositionOpen( ORDER_TYPE_SELL, slPrice, InpTPSLRatio );
      }
   }
}

void CClass::RunStandard() {

   int trend3 = TestSupertrend( 3 ); // candle 3
   int trend2 = TestSupertrend( 2 ); // candle 2
   int trend1 = TestSupertrend( 1 ); // candle 1

   // Buy Trade
   if ( trend3 != 3 && trend2 == 3 && trend1 == 3 ) { // enter a buy
      double slPrice = mSupertrend2.Lower( 0 );
      PositionOpen( ORDER_TYPE_BUY, slPrice, InpTPSLRatio );
   }

   // Sell Trade
   if ( trend3 != -3 && trend2 == -3 && trend1 == -3 ) { // enter a sell
      double slPrice = mSupertrend2.Upper( 0 );
      PositionOpen( ORDER_TYPE_SELL, slPrice, InpTPSLRatio );
   }
}

int CClass::TestSupertrend( int index ) {

   int result = 0;

   result += ( mSupertrend1.Lower( index ) != EMPTY_VALUE ) ? 1 : -1;
   result += ( mSupertrend2.Lower( index ) != EMPTY_VALUE ) ? 1 : -1;
   result += ( mSupertrend3.Lower( index ) != EMPTY_VALUE ) ? 1 : -1;

   return result;
}

void CClass::RunStochRSI() {

   if ( PositionInfo.Count( mSymbol, InpMagic ) > 0 ) return; // no double trading

   double close   = iClose( mSymbol, mTimeframe, 1 );
   int    trend   = TestSupertrend( 1 );
   double slPrice = 0;

   if ( mStochR.Main( 1 ) < InpSRSIOversold ) {
      if ( mStochDirection == STOCH_DIRECTION_SELL ) mStochDirection = STOCH_DIRECTION_NONE;
      if ( mStochR.CrossUpBufferPair( 0, 1, 1 ) ) mStochDirection = STOCH_DIRECTION_BUY;
   }

   if ( mStochR.Main( 1 ) > InpSRSIOverbought ) {
      if ( mStochDirection == STOCH_DIRECTION_BUY ) mStochDirection = STOCH_DIRECTION_NONE;
      if ( mStochR.CrossDownBufferPair( 0, 1, 1 ) ) mStochDirection = STOCH_DIRECTION_SELL;
   }

   // Buy Trade
   if ( close > mMA.Main( 1 ) ) {
      if ( mStochDirection == STOCH_DIRECTION_BUY ) {
         if ( trend >= 2 ) {
            if ( mSupertrend1.Lower( 1 ) != EMPTY_VALUE && mSupertrend2.Lower( 1 ) != EMPTY_VALUE ) {
               slPrice = mSupertrend2.Lower( 1 );
            }
            else {
               slPrice = mSupertrend3.Lower( 1 );
            }
            PositionOpen( ORDER_TYPE_BUY, slPrice, InpTPSLRatio );
         }
      }
   }

   // Sell trade
   if ( close < mMA.Main( 1 ) ) {
      if ( mStochDirection == STOCH_DIRECTION_SELL ) {
         if ( trend <= -2 ) {
            if ( mSupertrend1.Upper( 1 ) != EMPTY_VALUE && mSupertrend2.Upper( 1 ) != EMPTY_VALUE ) {
               slPrice = mSupertrend2.Upper( 1 );
            }
            else {
               slPrice = mSupertrend3.Upper( 1 );
            }
            PositionOpen( ORDER_TYPE_SELL, slPrice, InpTPSLRatio );
         }
      }
   }

   //   double upper1     = mSupertrend1.Upper( 0 ); // 1
   //   double lower1     = mSupertrend1.Lower( 0 ); // 1
   //   double upper2     = mSupertrend1.Upper( 0 ); // 1
   //   double lower2     = mSupertrend1.Lower( 0 ); // 1
   //   double upper3     = mSupertrend1.Upper( 0 ); // 1
   //   double lower3     = mSupertrend1.Lower( 0 ); // 1
   //
   //   int    upperCount = ( ( upper1 != EMPTY_VALUE ) + ( upper2 != EMPTY_VALUE ) + ( upper3 != EMPTY_VALUE ) );
   //   int    lowerCount = ( ( lower1 != EMPTY_VALUE ) + ( lower2 != EMPTY_VALUE ) + ( lower3 != EMPTY_VALUE ) );
   //
   //	// only buy over ma
   //	double close = iClose(mSymbol, mTimeframe, 1);
   //	if (close>mMA.Main(1)) {
   //
   //	}
   //
   //	// only sell below ma
   //	if (close < mMA.Main(1)) {
   //		// Only if stoch crosses down above 80
   //
   //	}

   //   bool conditionOpenBuy  = (                                                                    //
   //      ( InpTradeDirection == TRADE_DIRECTION_BOTH || InpTradeDirection == TRADE_DIRECTION_BUY ) // Selected trade direction
   //      && lower > 0                                                                              // condition met
   //      && PositionInfo.Count( mSymbol, mMagic, POSITION_TYPE_BUY ) <= InpMaxTrades               // not too many trades
   //   );
   //   bool conditionOpenSell = (                                                                    //
   //      ( InpTradeDirection == TRADE_DIRECTION_BOTH || InpTradeDirection == TRADE_DIRECTION_SELL ) // Selected trade direction
   //      && upper > 0                                                                               // condition met
   //      && PositionInfo.Count( mSymbol, mMagic, POSITION_TYPE_SELL ) <= InpMaxTrades               // not too many trades
   //   );

   //   bool conditionCloseBuy  = (          //
   //      upper > 0                        // main zz has reversed
   //      || ( InpUseZZTS && upperTS > 0 ) // ts has reversed
   //   );
   //
   //   bool conditionCloseSell = (         //
   //      lower > 0                        // main zz has reversed
   //      || ( InpUseZZTS && lowerTS > 0 ) // ts has reversed
   //   );
   //
   //   if ( conditionCloseBuy ) {
   //      if ( InpUseNettClose ) {
   //         CloseNett( POSITION_TYPE_BUY );
   //      }
   //      else {
   //         CloseAll( POSITION_TYPE_BUY );
   //      }
   //   }
   //   if ( conditionCloseSell ) {
   //      if ( InpUseNettClose ) {
   //         CloseNett( POSITION_TYPE_SELL );
   //      }
   //      else {
   //         CloseAll( POSITION_TYPE_SELL );
   //      }
   //   }
   //
   //   if ( !newBar ) return true;
   //
   //   upper                  = mZigZag.Upper( 1 ); // 1
   //   lower                  = mZigZag.Lower( 1 ); // 1
   //
   //   bool conditionOpenBuy  = (                                                                    //
   //      ( InpTradeDirection == TRADE_DIRECTION_BOTH || InpTradeDirection == TRADE_DIRECTION_BUY ) // Selected trade direction
   //      && lower > 0                                                                              // condition met
   //      && PositionInfo.Count( mSymbol, mMagic, POSITION_TYPE_BUY ) <= InpMaxTrades               // not too many trades
   //   );
   //   bool conditionOpenSell = (                                                                    //
   //      ( InpTradeDirection == TRADE_DIRECTION_BOTH || InpTradeDirection == TRADE_DIRECTION_SELL ) // Selected trade direction
   //      && upper > 0                                                                               // condition met
   //      && PositionInfo.Count( mSymbol, mMagic, POSITION_TYPE_SELL ) <= InpMaxTrades               // not too many trades
   //   );
   //
   //   if ( conditionOpenBuy ) {
   //      OpenOrder( ORDER_TYPE_BUY_LIMIT, lower );
   //   }
   //
   //   if ( conditionOpenSell ) {
   //      OpenOrder( ORDER_TYPE_SELL_LIMIT, upper );
   //   }

   return;
}

// bool CClass::CloseAll( ENUM_POSITION_TYPE type ) {
//
//    bool success = ClosePositions( type );
//    success &= DeleteOrders( type + ( ORDER_TYPE_BUY_LIMIT - ORDER_TYPE_BUY ) );
//
//    return success;
// }

// bool CClass::CloseAtSL( ENUM_POSITION_TYPE type, double currentPrice ) {
//
//    double totalOpenPrice;
//    int    count = PositionInfo.TotalOpenPrice( mSymbol, mMagic, type, totalOpenPrice );
//    if ( count == 0 ) return true;
//    double averageOpenPrice = totalOpenPrice / count;
//    CloseAll( type );
//    return true;
// }

// bool CClass::CloseNett( ENUM_POSITION_TYPE type ) {
//
//    int    tn = type % 2;
//    double trades[][2];
//    ArrayResize( trades, 0 );
//    int  tradeCount = 0;
//    bool success    = DeleteOrders( type + ( ORDER_TYPE_BUY_LIMIT - ORDER_TYPE_BUY ) );
//    for ( int i = PositionInfo.Total() - 1; i >= 0; i-- ) {
//
//       if ( !PositionInfo.SelectByIndex( i, mSymbol, mMagic, type ) ) continue;
//       if ( PositionInfo.Profit() < 0 ) {
//          tradeCount++;
//          ArrayResize( trades, tradeCount );
//          trades[tradeCount - 1][0] = PositionInfo.Profit();
//          trades[tradeCount - 1][1] = ( double )PositionInfo.Ticket();
//          continue;
//       }
//       success &= Trade.PositionClose( PositionInfo.Ticket() );
//       nettProfit[tn] += PositionInfo.Profit();
//    }
//
//    bool allClosed = true;
//    if ( tradeCount > 0 ) {
//       ArraySort( trades );
//       for ( int i = 0; i < tradeCount; i++ ) {
//          if ( ( nettProfit[tn] + trades[i][0] ) > 0 ) {
//             success &= Trade.PositionClose( ( int )trades[i][1] );
//             nettProfit[tn] += trades[i][0];
//          }
//          else {
//             allClosed = false;
//             break;
//          }
//       }
//    }
//
//    if ( allClosed ) nettProfit[tn] = 0;
//
//    return success;
// }

// bool CClass::DeleteOrders( int type ) {
//
//    bool success = true;
//    for ( int i = OrderInfo.Total() - 1; i >= 0; i-- ) {
//
//       if ( !OrderInfo.SelectByIndex( i, mSymbol, mMagic, type ) ) continue;
//       success &= Trade.OrderDelete( OrderInfo.Ticket() );
//    }
//    return success;
// }

// bool CClass::ClosePositions( ENUM_POSITION_TYPE type ) {
//
//    bool success = true;
//    for ( int i = PositionInfo.Total() - 1; i >= 0; i-- ) {
//
//       if ( !PositionInfo.SelectByIndex( i, mSymbol, mMagic, type ) ) continue;
//       success &= Trade.PositionClose( PositionInfo.Ticket() );
//    }
//    return success;
// }

bool CClass::PositionOpen( ENUM_ORDER_TYPE type, double slPrice, double tpRatio ) {

   double price   = OpenPrice( mSymbol, type );
   double tp      = tpRatio * ( price - slPrice );
   double tpPrice = price + tp;
   int    digits  = ( int )SymbolInfoInteger( mSymbol, SYMBOL_DIGITS );

   price          = NormalizeDouble( price, digits );
   slPrice        = NormalizeDouble( slPrice, digits );
   tpPrice        = NormalizeDouble( tpPrice, digits );

#ifdef __MQL4__
   return ( OrderSend( mSymbol, type, InpVolume, price, 0, slPrice, tpPrice, InpTradeComment, InpMagic, 0 ) > 0 );
#endif
#ifdef __MQL5__
   return Trade.PositionOpen( mSymbol, type, InpVolume, price, slPrice, tpPrice, InpTradeComment );
#endif
}

// bool CClass::OpenOrder( ENUM_ORDER_TYPE type, double price ) {
//
// #ifdef __MQL4__
//    return ( OrderSend( mSymbol, type, InpVolume, price, 0, 0, 0, InpTradeComment, InpMagic, 0 ) > 0 );
// #endif
// #ifdef __MQL5__
//    return Trade.OrderOpen( mSymbol, type, InpVolume, 0, price, 0, 0, ORDER_TIME_GTC, 0, InpTradeComment );
// #endif
// }

#undef CClass
#undef CParent
