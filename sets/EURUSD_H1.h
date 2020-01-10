//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_Envelopes_EURUSD_H1_Params : Stg_Envelopes_Params {
  Stg_Envelopes_EURUSD_H1_Params() {
    symbol = "EURUSD";
    tf = PERIOD_H1;
    Envelopes_Period = 2;
    Envelopes_Applied_Price = 3;
    Envelopes_Shift = 0;
    Envelopes_TrailingStopMethod = 6;
    Envelopes_TrailingProfitMethod = 11;
    Envelopes_SignalOpenLevel = 36;
    Envelopes_SignalBaseMethod = 0;
    Envelopes_SignalOpenMethod1 = 195;
    Envelopes_SignalOpenMethod2 = 0;
    Envelopes_SignalCloseLevel = 36;
    Envelopes_SignalCloseMethod1 = 1;
    Envelopes_SignalCloseMethod2 = 0;
    Envelopes_MaxSpread = 6;
  }
};
