//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/**
 * @file
 * Implements Envelopes strategy the Envelopes indicator.
 */

// Includes.
#include <EA31337-classes/Indicators/Indi_Envelopes.mqh>
#include <EA31337-classes/Strategy.mqh>

// User input params.
INPUT string __Envelopes_Parameters__ = "-- Envelopes strategy params --";  // >>> ENVELOPES <<<
INPUT int Envelopes_Active_Tf = 4;             // Activate timeframes (1-255, e.g. M1=1,M5=2,M15=4,M30=8,H1=16,H2=32...)
INPUT int Envelopes_MA_Period = 6;             // Period
INPUT double Envelopes_Deviation = 0.5;        // Deviation for M1
INPUT ENUM_MA_METHOD Envelopes_MA_Method = 3;  // MA Method
INPUT int Envelopes_MA_Shift = 0;              // MA Shift
INPUT ENUM_APPLIED_PRICE Envelopes_Applied_Price = 3;       // Applied Price
INPUT int Envelopes_Shift = 0;                              // Shift
INPUT ENUM_TRAIL_TYPE Envelopes_TrailingStopMethod = 23;    // Trail stop method
INPUT ENUM_TRAIL_TYPE Envelopes_TrailingProfitMethod = -2;  // Trail profit method
/* @todo INPUT */ int Envelopes_SignalOpenLevel = 0;        // Signal open level
INPUT int Envelopes1_SignalBaseMethod = 48;                 // Signal base method (-127-127)
INPUT int Envelopes1_OpenCondition1 = 1;                    // Open condition 1 (0-1023)
INPUT int Envelopes1_OpenCondition2 = 0;                    // Open condition 2 (0-1023)
INPUT ENUM_MARKET_EVENT Envelopes1_CloseCondition = 13;     // Close condition for M1
INPUT double Envelopes_MaxSpread = 6.0;                     // Max spread to trade (pips)

// Struct to define strategy parameters to override.
struct Stg_Envelopes_Params : Stg_Params {
  unsigned int Envelopes_Period;
  ENUM_APPLIED_PRICE Envelopes_Applied_Price;
  int Envelopes_Shift;
  ENUM_TRAIL_TYPE Envelopes_TrailingStopMethod;
  ENUM_TRAIL_TYPE Envelopes_TrailingProfitMethod;
  double Envelopes_SignalOpenLevel;
  long Envelopes_SignalBaseMethod;
  long Envelopes_SignalOpenMethod1;
  long Envelopes_SignalOpenMethod2;
  double Envelopes_SignalCloseLevel;
  ENUM_MARKET_EVENT Envelopes_SignalCloseMethod1;
  ENUM_MARKET_EVENT Envelopes_SignalCloseMethod2;
  double Envelopes_MaxSpread;

  // Constructor: Set default param values.
  Stg_Envelopes_Params()
      : Envelopes_Period(::Envelopes_Period),
        Envelopes_Applied_Price(::Envelopes_Applied_Price),
        Envelopes_Shift(::Envelopes_Shift),
        Envelopes_TrailingStopMethod(::Envelopes_TrailingStopMethod),
        Envelopes_TrailingProfitMethod(::Envelopes_TrailingProfitMethod),
        Envelopes_SignalOpenLevel(::Envelopes_SignalOpenLevel),
        Envelopes_SignalBaseMethod(::Envelopes_SignalBaseMethod),
        Envelopes_SignalOpenMethod1(::Envelopes_SignalOpenMethod1),
        Envelopes_SignalOpenMethod2(::Envelopes_SignalOpenMethod2),
        Envelopes_SignalCloseLevel(::Envelopes_SignalCloseLevel),
        Envelopes_SignalCloseMethod1(::Envelopes_SignalCloseMethod1),
        Envelopes_SignalCloseMethod2(::Envelopes_SignalCloseMethod2),
        Envelopes_MaxSpread(::Envelopes_MaxSpread) {}
};

// Loads pair specific param values.
#include "sets/EURUSD_H1.h"
#include "sets/EURUSD_H4.h"
#include "sets/EURUSD_M1.h"
#include "sets/EURUSD_M15.h"
#include "sets/EURUSD_M30.h"
#include "sets/EURUSD_M5.h"

class Stg_Envelopes : public Strategy {
 public:
  Stg_Envelopes(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_Envelopes *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    Stg_Envelopes_Params _params;
    switch (_tf) {
      case PERIOD_M1: {
        Stg_Envelopes_EURUSD_M1_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M5: {
        Stg_Envelopes_EURUSD_M5_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M15: {
        Stg_Envelopes_EURUSD_M15_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M30: {
        Stg_Envelopes_EURUSD_M30_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_H1: {
        Stg_Envelopes_EURUSD_H1_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_H4: {
        Stg_Envelopes_EURUSD_H4_Params _new_params;
        _params = _new_params;
      }
    }
    // Initialize strategy parameters.
    ChartParams cparams(_tf);
    Envelopes_Params adx_params(_params.Envelopes_Period, _params.Envelopes_Applied_Price);
    IndicatorParams adx_iparams(10, INDI_Envelopes);
    StgParams sparams(new Trade(_tf, _Symbol), new Indi_Envelopes(adx_params, adx_iparams, cparams), NULL, NULL);
    sparams.logger.SetLevel(_log_level);
    sparams.SetMagicNo(_magic_no);
    sparams.SetSignals(_params.Envelopes_SignalBaseMethod, _params.Envelopes_SignalOpenMethod1,
                       _params.Envelopes_SignalOpenMethod2, _params.Envelopes_SignalCloseMethod1,
                       _params.Envelopes_SignalCloseMethod2, _params.Envelopes_SignalOpenLevel,
                       _params.Envelopes_SignalCloseLevel);
    sparams.SetStops(_params.Envelopes_TrailingProfitMethod, _params.Envelopes_TrailingStopMethod);
    sparams.SetMaxSpread(_params.Envelopes_MaxSpread);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_Envelopes(sparams, "Envelopes");
    return _strat;
  }

  /**
   * Check if Envelopes indicator is on sell.
   *
   * @param
   *   _cmd (int) - type of trade order command
   *   period (int) - period to check for
   *   _signal_method (int) - signal method to use by using bitwise AND operation
   *   _signal_level1 (double) - signal level to consider the signal
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, long _signal_method = EMPTY, double _signal_level = EMPTY) {
    bool _result = false;
    double envelopes_0_main = ((Indi_Envelopes *)this.Data()).GetValue(LINE_MAIN, 0);
    double envelopes_0_lower = ((Indi_Envelopes *)this.Data()).GetValue(LINE_LOWER, 0);
    double envelopes_0_upper = ((Indi_Envelopes *)this.Data()).GetValue(LINE_UPPER, 0);
    double envelopes_1_main = ((Indi_Envelopes *)this.Data()).GetValue(LINE_MAIN, 1);
    double envelopes_1_lower = ((Indi_Envelopes *)this.Data()).GetValue(LINE_LOWER, 1);
    double envelopes_1_upper = ((Indi_Envelopes *)this.Data()).GetValue(LINE_UPPER, 1);
    double envelopes_2_main = ((Indi_Envelopes *)this.Data()).GetValue(LINE_MAIN, 2);
    double envelopes_2_lower = ((Indi_Envelopes *)this.Data()).GetValue(LINE_LOWER, 2);
    double envelopes_2_upper = ((Indi_Envelopes *)this.Data()).GetValue(LINE_UPPER, 2);
    if (_signal_method == EMPTY) _signal_method = GetSignalBaseMethod();
    if (_signal_level1 == EMPTY) _signal_level1 = GetSignalLevel1();
    if (_signal_level2 == EMPTY) _signal_level2 = GetSignalLevel2();
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        _result = Low[CURR] < envelopes_0_lower || Low[PREV] < envelopes_0_lower;  // price low was below the lower band
        // _result = _result || (envelopes_0_main > envelopes_2_main && Open[CURR] > envelopes_0_upper);
        if (_signal_method != 0) {
          if (METHOD(_signal_method, 0)) _result &= Open[CURR] > envelopes_0_lower;  // FIXME
          if (METHOD(_signal_method, 1)) _result &= envelopes_0_main < envelopes_1_main;
          if (METHOD(_signal_method, 2)) _result &= envelopes_0_lower < envelopes_1_lower;
          if (METHOD(_signal_method, 3)) _result &= envelopes_0_upper < envelopes_1_upper;
          if (METHOD(_signal_method, 4))
            _result &= envelopes_0_upper - envelopes_0_lower > envelopes_1_upper - envelopes_1_lower;
          if (METHOD(_signal_method, 5)) _result &= this.Chart().GetAsk() < envelopes_0_main;
          if (METHOD(_signal_method, 6)) _result &= Close[CURR] < envelopes_0_upper;
          // if (METHOD(_signal_method, 7)) _result &= _chart.GetAsk() > Close[PREV];
        }
        break;
      case ORDER_TYPE_SELL:
        _result =
            High[CURR] > envelopes_0_upper || High[PREV] > envelopes_0_upper;  // price high was above the upper band
        // _result = _result || (envelopes_0_main < envelopes_2_main && Open[CURR] < envelopes_0_lower);
        if (_signal_method != 0) {
          if (METHOD(_signal_method, 0)) _result &= Open[CURR] < envelopes_0_upper;  // FIXME
          if (METHOD(_signal_method, 1)) _result &= envelopes_0_main > envelopes_1_main;
          if (METHOD(_signal_method, 2)) _result &= envelopes_0_lower > envelopes_1_lower;
          if (METHOD(_signal_method, 3)) _result &= envelopes_0_upper > envelopes_1_upper;
          if (METHOD(_signal_method, 4))
            _result &= envelopes_0_upper - envelopes_0_lower > envelopes_1_upper - envelopes_1_lower;
          if (METHOD(_signal_method, 5)) _result &= this.Chart().GetAsk() > envelopes_0_main;
          if (METHOD(_signal_method, 6)) _result &= Close[CURR] > envelopes_0_upper;
          // if (METHOD(_signal_method, 7)) _result &= _chart.GetAsk() < Close[PREV];
        }
        break;
    }
    return _result;
  }

  /**
   * Check strategy's closing signal.
   */
  bool SignalClose(ENUM_ORDER_TYPE _cmd, long _signal_method = EMPTY, double _signal_level = EMPTY) {
    if (_signal_level == EMPTY) _signal_level = GetSignalCloseLevel();
    return SignalOpen(Order::NegateOrderType(_cmd), _signal_method, _signal_level);
  }
};
