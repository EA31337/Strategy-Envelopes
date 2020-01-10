//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_Envelopes_EURUSD_M1_Params : Stg_Envelopes_Params {
  Stg_Envelopes_EURUSD_M1_Params() {
    symbol = "EURUSD";
    tf = PERIOD_M1;
    Envelopes_Period = 32;
    Envelopes_Applied_Price = 3;
    Envelopes_Shift = 0;
    Envelopes_TrailingStopMethod = 6;
    Envelopes_TrailingProfitMethod = 11;
    Envelopes_SignalOpenLevel = 36;
    Envelopes_SignalBaseMethod = 0;
    Envelopes_SignalOpenMethod1 = 0;
    Envelopes_SignalOpenMethod2 = 0;
    Envelopes_SignalCloseLevel = 36;
    Envelopes_SignalCloseMethod1 = 0;
    Envelopes_SignalCloseMethod2 = 0;
    Envelopes_MaxSpread = 2;
  }
};
