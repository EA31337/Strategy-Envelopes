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
INPUT int Envelopes_MA_Period = 6;                                          // Period
INPUT double Envelopes_Deviation = 0.5;                                     // Deviation for M1
INPUT ENUM_MA_METHOD Envelopes_MA_Method = 3;                               // MA Method
INPUT int Envelopes_MA_Shift = 0;                                           // MA Shift
INPUT ENUM_APPLIED_PRICE Envelopes_Applied_Price = 3;                       // Applied Price
INPUT int Envelopes_Shift = 0;                                              // Shift
INPUT int Envelopes_SignalOpenMethod = 48;                                  // Signal open method (-127-127)
INPUT int Envelopes_SignalOpenLevel = 0;                                    // Signal open level
INPUT int Envelopes_SignalCloseMethod = 48;                                 // Signal close method (-127-127)
INPUT int Envelopes_SignalCloseLevel = 0;                                   // Signal close level
INPUT int Envelopes_PriceLimitMethod = 0;                                   // Price limit method
INPUT double Envelopes_PriceLimitLevel = 0;                                 // Price limit level
INPUT double Envelopes_MaxSpread = 6.0;                                     // Max spread to trade (pips)

// Struct to define strategy parameters to override.
struct Stg_Envelopes_Params : Stg_Params {
  int Envelopes_MA_Period;
  double Envelopes_Deviation;
  ENUM_MA_METHOD Envelopes_MA_Method;
  int Envelopes_MA_Shift;
  ENUM_APPLIED_PRICE Envelopes_Applied_Price;
  int Envelopes_Shift;
  double Envelopes_SignalOpenLevel;
  int Envelopes_SignalOpenMethod;
  double Envelopes_SignalCloseLevel;
  int Envelopes_SignalCloseMethod;
  int Envelopes_PriceLimitMethod;
  double Envelopes_PriceLimitLevel;
  double Envelopes_MaxSpread;

  // Constructor: Set default param values.
  Stg_Envelopes_Params()
      : Envelopes_MA_Period(::Envelopes_MA_Period),
        Envelopes_Deviation(::Envelopes_Deviation),
        Envelopes_MA_Method(::Envelopes_MA_Method),
        Envelopes_MA_Shift(::Envelopes_MA_Shift),
        Envelopes_Applied_Price(::Envelopes_Applied_Price),
        Envelopes_Shift(::Envelopes_Shift),
        Envelopes_SignalOpenMethod(::Envelopes_SignalOpenMethod),
        Envelopes_SignalOpenLevel(::Envelopes_SignalOpenLevel),
        Envelopes_SignalCloseMethod(::Envelopes_SignalCloseMethod),
        Envelopes_SignalCloseLevel(::Envelopes_SignalCloseLevel),
        Envelopes_PriceLimitMethod(::Envelopes_PriceLimitMethod),
        Envelopes_PriceLimitLevel(::Envelopes_PriceLimitLevel),
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
    Envelopes_Params env_params(_params.Envelopes_MA_Period, _params.Envelopes_MA_Shift, _params.Envelopes_MA_Method, _params.Envelopes_Applied_Price, _params.Envelopes_Deviation);
    IndicatorParams env_iparams(10, INDI_ENVELOPES);
    StgParams sparams(new Trade(_tf, _Symbol), new Indi_Envelopes(env_params, env_iparams, cparams), NULL, NULL);
    sparams.logger.SetLevel(_log_level);
    sparams.SetMagicNo(_magic_no);
    sparams.SetSignals(_params.Envelopes_SignalOpenMethod, _params.Envelopes_SignalOpenMethod,
                       _params.Envelopes_SignalCloseMethod, _params.Envelopes_SignalCloseMethod);
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
   *   _method (int) - signal method to use by using bitwise AND operation
   *   _level (double) - signal level to consider the signal
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, double _level = 0.0) {
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
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        _result = Low[CURR] < envelopes_0_lower || Low[PREV] < envelopes_0_lower;  // price low was below the lower band
        // _result = _result || (envelopes_0_main > envelopes_2_main && Open[CURR] > envelopes_0_upper);
        if (_method != 0) {
          if (METHOD(_method, 0)) _result &= Open[CURR] > envelopes_0_lower;  // FIXME
          if (METHOD(_method, 1)) _result &= envelopes_0_main < envelopes_1_main;
          if (METHOD(_method, 2)) _result &= envelopes_0_lower < envelopes_1_lower;
          if (METHOD(_method, 3)) _result &= envelopes_0_upper < envelopes_1_upper;
          if (METHOD(_method, 4))
            _result &= envelopes_0_upper - envelopes_0_lower > envelopes_1_upper - envelopes_1_lower;
          if (METHOD(_method, 5)) _result &= this.Chart().GetAsk() < envelopes_0_main;
          if (METHOD(_method, 6)) _result &= Close[CURR] < envelopes_0_upper;
          // if (METHOD(_method, 7)) _result &= _chart.GetAsk() > Close[PREV];
        }
        break;
      case ORDER_TYPE_SELL:
        _result =
            High[CURR] > envelopes_0_upper || High[PREV] > envelopes_0_upper;  // price high was above the upper band
        // _result = _result || (envelopes_0_main < envelopes_2_main && Open[CURR] < envelopes_0_lower);
        if (_method != 0) {
          if (METHOD(_method, 0)) _result &= Open[CURR] < envelopes_0_upper;  // FIXME
          if (METHOD(_method, 1)) _result &= envelopes_0_main > envelopes_1_main;
          if (METHOD(_method, 2)) _result &= envelopes_0_lower > envelopes_1_lower;
          if (METHOD(_method, 3)) _result &= envelopes_0_upper > envelopes_1_upper;
          if (METHOD(_method, 4))
            _result &= envelopes_0_upper - envelopes_0_lower > envelopes_1_upper - envelopes_1_lower;
          if (METHOD(_method, 5)) _result &= this.Chart().GetAsk() > envelopes_0_main;
          if (METHOD(_method, 6)) _result &= Close[CURR] > envelopes_0_upper;
          // if (METHOD(_method, 7)) _result &= _chart.GetAsk() < Close[PREV];
        }
        break;
    }
    return _result;
  }

  /**
   * Check strategy's closing signal.
   */
  bool SignalClose(ENUM_ORDER_TYPE _cmd, int _method = 0, double _level = 0.0) {
    return SignalOpen(Order::NegateOrderType(_cmd), _method, _level);
  }

  /**
   * Gets price limit value for profit take or stop loss.
   */
  double PriceLimit(ENUM_ORDER_TYPE _cmd, ENUM_STG_PRICE_LIMIT_MODE _mode, int _method = 0, double _level = 0.0) {
    double _trail = _level * Market().GetPipSize();
    int _direction = Order::OrderDirection(_cmd) * (_mode == LIMIT_VALUE_STOP ? -1 : 1);
    double _default_value = Market().GetCloseOffer(_cmd) + _trail * _method * _direction;
    double _result = _default_value;
    switch (_method) {
      case 0: {
        // @todo
      }
    }
    return _result;
  }
};
