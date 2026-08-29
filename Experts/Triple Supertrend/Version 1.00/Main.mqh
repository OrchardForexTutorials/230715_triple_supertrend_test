/*
   Triple Supertrend

   Copyright 2013-2023, Novateq Pty Ltd
   http://novateq.com.au

*/

#property strict

#include "Defines.mqh"
#include "Expert.mqh"

CExpert Expert;

#ifdef CLicence
CLicence *Licence;
bool      LicenceValid     = false;
datetime  LicenceCheckTime = 0;
#endif

int OnInit() {

#ifdef CLicence
   Licence = new CLicence();
   Licence.AllowDemo( true );
   Licence.AllowTester( true );
#endif

#ifdef app_trial
   datetime compileTime = __DATETIME__;
   datetime expiryTime  = compileTime + ( 62 * 24 * 60 * 60 );
   if ( TimeLocal() > expiryTime ) {
      Print( "Pre release test version has expired" );
      return INIT_FAILED;
   }
#endif

   return INIT_SUCCEEDED;
}

void OnDeinit( const int reason ) {

#ifdef CLicence
   delete Licence;
#endif
}

void OnTick() {

#ifdef CLicence
   if ( TimeGMT() > LicenceCheckTime ) {
      LicenceValid     = Licence.Check();
      LicenceCheckTime = Licence.RecheckTime();
      if ( !LicenceValid ) {
         Print( "Licence invalid, expert will not run" );
      }
   }

   if ( !LicenceValid ) return;
#endif

   Expert.OnTick();

   return;
}
