/**
 * @file
 * Implements Envelopes strategy the Envelopes indicator.
 */

// User input params.
INPUT string __Envelopes_Parameters__ = "-- Envelopes strategy params --";  // >>> ENVELOPES <<<
INPUT float Envelopes_LotSize = 0;                                          // Lot size
INPUT int Envelopes_SignalOpenMethod = 0;                                   // Signal open method (-127-127)
INPUT float Envelopes_SignalOpenLevel = 0.0f;                               // Signal open level
INPUT int Envelopes_SignalOpenFilterMethod = 1;                             // Signal open filter method
INPUT int Envelopes_SignalOpenBoostMethod = 0;                              // Signal open filter method
INPUT int Envelopes_SignalCloseMethod = 0;                                  // Signal close method (-127-127)
INPUT float Envelopes_SignalCloseLevel = 0.0f;                              // Signal close level
INPUT int Envelopes_PriceStopMethod = 0;                                    // Price stop method
INPUT float Envelopes_PriceStopLevel = 0;                                   // Price stop level
INPUT int Envelopes_TickFilterMethod = 1;                                   // Tick filter method
INPUT float Envelopes_MaxSpread = 4.0;                                      // Max spread to trade (pips)
INPUT short Envelopes_Shift = 0;                                            // Shift
INPUT int Envelopes_OrderCloseTime = -20;  // Order close time in mins (>0) or bars (<0)
INPUT string __Envelopes_Indi_Envelopes_Parameters__ =
    "-- Envelopes strategy: Envelopes indicator params --";  // >>> Envelopes strategy: Envelopes indicator <<<
INPUT int Envelopes_Indi_Envelopes_MA_Period = 14;           // Period
INPUT int Envelopes_Indi_Envelopes_MA_Shift = 0;             // MA Shift
INPUT ENUM_MA_METHOD Envelopes_Indi_Envelopes_MA_Method = (ENUM_MA_METHOD)3;              // MA Method
INPUT ENUM_APPLIED_PRICE Envelopes_Indi_Envelopes_Applied_Price = (ENUM_APPLIED_PRICE)3;  // Applied Price
INPUT float Envelopes_Indi_Envelopes_Deviation = 0.5;                                     // Deviation for M1
INPUT int Envelopes_Indi_Envelopes_Shift = 0;                                             // Shift

// Structs.

// Defines struct with default user indicator values.
struct Indi_Envelopes_Params_Defaults : EnvelopesParams {
  Indi_Envelopes_Params_Defaults()
      : EnvelopesParams(::Envelopes_Indi_Envelopes_MA_Period, ::Envelopes_Indi_Envelopes_MA_Shift,
                        ::Envelopes_Indi_Envelopes_MA_Method, ::Envelopes_Indi_Envelopes_Applied_Price,
                        ::Envelopes_Indi_Envelopes_Deviation, ::Envelopes_Indi_Envelopes_Shift) {}
} indi_env_defaults;

// Defines struct with default user strategy values.
struct Stg_Envelopes_Params_Defaults : StgParams {
  Stg_Envelopes_Params_Defaults()
      : StgParams(::Envelopes_SignalOpenMethod, ::Envelopes_SignalOpenFilterMethod, ::Envelopes_SignalOpenLevel,
                  ::Envelopes_SignalOpenBoostMethod, ::Envelopes_SignalCloseMethod, ::Envelopes_SignalCloseLevel,
                  ::Envelopes_PriceStopMethod, ::Envelopes_PriceStopLevel, ::Envelopes_TickFilterMethod,
                  ::Envelopes_MaxSpread, ::Envelopes_Shift, ::Envelopes_OrderCloseTime) {}
} stg_env_defaults;

// Struct to define strategy parameters to override.
struct Stg_Envelopes_Params : StgParams {
  EnvelopesParams iparams;
  StgParams sparams;

  // Struct constructors.
  Stg_Envelopes_Params(EnvelopesParams &_iparams, StgParams &_sparams)
      : iparams(indi_env_defaults, _iparams.tf), sparams(stg_env_defaults) {
    iparams = _iparams;
    sparams = _sparams;
  }
};

// Loads pair specific param values.
#include "config/EURUSD_H1.h"
#include "config/EURUSD_H4.h"
#include "config/EURUSD_H8.h"
#include "config/EURUSD_M1.h"
#include "config/EURUSD_M15.h"
#include "config/EURUSD_M30.h"
#include "config/EURUSD_M5.h"

class Stg_Envelopes : public Strategy {
 public:
  Stg_Envelopes(StgParams &_sparams, TradeParams &_tparams, ChartParams &_cparams, string _name = "")
      : Strategy(_sparams, _tparams, _cparams, _name) {}

  static Stg_Envelopes *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    EnvelopesParams _indi_params(indi_env_defaults, _tf);
    StgParams _stg_params(stg_env_defaults);
#ifdef __config__
    SetParamsByTf<EnvelopesParams>(_indi_params, _tf, indi_env_m1, indi_env_m5, indi_env_m15, indi_env_m30, indi_env_h1,
                                   indi_env_h4, indi_env_h8);
    SetParamsByTf<StgParams>(_stg_params, _tf, stg_env_m1, stg_env_m5, stg_env_m15, stg_env_m30, stg_env_h1, stg_env_h4,
                             stg_env_h8);
#endif
    // Initialize indicator.
    EnvelopesParams env_params(_indi_params);
    _stg_params.SetIndicator(new Indi_Envelopes(_indi_params));
    // Initialize Strategy instance.
    ChartParams _cparams(_tf, _Symbol);
    TradeParams _tparams(_magic_no, _log_level);
    Strategy *_strat = new Stg_Envelopes(_stg_params, _tparams, _cparams, "Envelopes");
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    Chart *_chart = trade.GetChart();
    Indi_Envelopes *_indi = GetIndicator();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    bool _result = _is_valid;
    if (!_result) {
      // Returns false when indicator data is not valid.
      return false;
    }
    double level = _level * Chart().GetPipSize();
    double ask = Chart().GetAsk();
    double bid = Chart().GetBid();
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        _result = Low[CURR] < _indi[CURR][(int)LINE_LOWER] ||
                  Low[PREV] < _indi[CURR][(int)LINE_LOWER];  // price low was below the lower band
        // _result = _result || (_indi[CURR]_main > _indi[PPREV]_main && Open[CURR] > _indi[CURR][(int)LINE_UPPER]);
        if (_method != 0) {
          if (METHOD(_method, 0)) _result &= Chart().GetOpen() > _indi[CURR][(int)LINE_LOWER];  // FIXME
          if (METHOD(_method, 1))
            _result &= (_indi[CURR][(int)LINE_UPPER] - _indi[CURR][(int)LINE_LOWER]) / 2 <
                       (_indi[PREV][(int)LINE_UPPER] - _indi[PREV][(int)LINE_LOWER]) / 2;
          if (METHOD(_method, 2)) _result &= _indi[CURR][(int)LINE_LOWER] < _indi[PREV][(int)LINE_LOWER];
          if (METHOD(_method, 3)) _result &= _indi[CURR][(int)LINE_UPPER] < _indi[PREV][(int)LINE_UPPER];
          if (METHOD(_method, 4))
            _result &= _indi[CURR][(int)LINE_UPPER] - _indi[CURR][(int)LINE_LOWER] >
                       _indi[PREV][(int)LINE_UPPER] - _indi[PREV][(int)LINE_LOWER];
          if (METHOD(_method, 5)) _result &= ask < (_indi[CURR][(int)LINE_UPPER] - _indi[CURR][(int)LINE_LOWER]) / 2;
          if (METHOD(_method, 6)) _result &= Chart().GetClose() < _indi[CURR][(int)LINE_UPPER];
          // if (METHOD(_method, 7)) _result &= _chart.GetAsk() > Close[PREV];
        }
        break;
      case ORDER_TYPE_SELL:
        _result = High[CURR] > _indi[CURR][(int)LINE_UPPER] ||
                  High[PREV] > _indi[CURR][(int)LINE_UPPER];  // price high was above the upper band
        // _result = _result || (_indi[CURR]_main < _indi[PPREV]_main && Open[CURR] < _indi[CURR][(int)LINE_LOWER]);
        if (_method != 0) {
          if (METHOD(_method, 0)) _result &= Chart().GetOpen() < _indi[CURR][(int)LINE_UPPER];  // FIXME
          if (METHOD(_method, 1))
            _result &= (_indi[CURR][(int)LINE_UPPER] - _indi[CURR][(int)LINE_LOWER]) / 2 >
                       (_indi[PREV][(int)LINE_UPPER] - _indi[PREV][(int)LINE_LOWER]) / 2;
          if (METHOD(_method, 2)) _result &= _indi[CURR][(int)LINE_LOWER] > _indi[PREV][(int)LINE_LOWER];
          if (METHOD(_method, 3)) _result &= _indi[CURR][(int)LINE_UPPER] > _indi[PREV][(int)LINE_UPPER];
          if (METHOD(_method, 4))
            _result &= _indi[CURR][(int)LINE_UPPER] - _indi[CURR][(int)LINE_LOWER] >
                       _indi[PREV][(int)LINE_UPPER] - _indi[PREV][(int)LINE_LOWER];
          if (METHOD(_method, 5)) _result &= ask > (_indi[CURR][(int)LINE_UPPER] - _indi[CURR][(int)LINE_LOWER]) / 2;
          if (METHOD(_method, 6)) _result &= Chart().GetClose() > _indi[CURR][(int)LINE_UPPER];
          // if (METHOD(_method, 7)) _result &= _chart.GetAsk() < Close[PREV];
        }
        break;
    }
    return _result;
  }

  /**
   * Check strategy's closing signal.
   */
  bool SignalClose(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0) {
    return SignalOpen(Order::NegateOrderType(_cmd), _method, _level);
  }

  /**
   * Gets price stop value for profit take or stop loss.
   */
  float PriceStop(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, float _level = 0.0) {
    Indi_Envelopes *_indi = GetIndicator();
    double _trail = _level * Market().GetPipSize();
    int _direction = Order::OrderDirection(_cmd, _mode);
    double _default_value = Market().GetCloseOffer(_cmd) + _trail * _direction;
    double _result = _default_value;

    if (GetLastError() > ERR_INDICATOR_DATA_NOT_FOUND) {
      // Returns false when indicator data is not ready.
      return false;
    }
    switch (_method) {
      case 1: {
        _result = (_direction > 0 ? _indi[CURR][(int)LINE_UPPER] : _indi[CURR][(int)LINE_LOWER]) + _trail * _direction;
        break;
      }
      case 2: {
        _result = (_direction > 0 ? _indi[PREV][(int)LINE_UPPER] : _indi[PREV][(int)LINE_LOWER]) + _trail * _direction;
        break;
      }
      case 3: {
        _result =
            (_direction > 0 ? _indi[PPREV][(int)LINE_UPPER] : _indi[PPREV][(int)LINE_LOWER]) + _trail * _direction;
        break;
      }
      case 4: {
        _result = (_direction > 0 ? fmax(_indi[PREV][(int)LINE_UPPER], _indi[PPREV][(int)LINE_UPPER])
                                  : fmin(_indi[PREV][(int)LINE_LOWER], _indi[PPREV][(int)LINE_LOWER])) +
                  _trail * _direction;
        break;
      }
      case 5: {
        _result = (_indi[CURR][(int)LINE_UPPER] - _indi[CURR][(int)LINE_LOWER]) / 2 + _trail * _direction;
        break;
      }
      case 6: {
        _result = (_indi[PREV][(int)LINE_UPPER] - _indi[PREV][(int)LINE_LOWER]) / 2 + _trail * _direction;
        break;
      }
      case 7: {
        _result = (_indi[PPREV][(int)LINE_UPPER] - _indi[PPREV][(int)LINE_LOWER]) / 2 + _trail * _direction;
        break;
      }
      case 8: {
        int _bar_count = (int)_level * (int)_indi.GetMAPeriod();
        _result = _direction > 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest<double>(_bar_count))
                                 : _indi.GetPrice(PRICE_LOW, _indi.GetLowest<double>(_bar_count));
        break;
      }
    }
    return (float)_result;
  }
};
