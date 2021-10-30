/**
 * @file
 * Implements Envelopes strategy the Envelopes indicator.
 */

// User input params.
INPUT_GROUP("Envelopes strategy: strategy params");
INPUT float Envelopes_LotSize = 0;                // Lot size
INPUT int Envelopes_SignalOpenMethod = 32;        // Signal open method (-127-127)
INPUT float Envelopes_SignalOpenLevel = 0.001f;   // Signal open level
INPUT int Envelopes_SignalOpenFilterMethod = 32;  // Signal open filter method
INPUT int Envelopes_SignalOpenFilterTime = 3;     // Signal open filter time
INPUT int Envelopes_SignalOpenBoostMethod = 0;    // Signal open boost method
INPUT int Envelopes_SignalCloseMethod = 0;        // Signal close method (-127-127)
INPUT int Envelopes_SignalCloseFilter = 0;        // Signal close filter (-127-127)
INPUT float Envelopes_SignalCloseLevel = 0.001f;  // Signal close level
INPUT int Envelopes_PriceStopMethod = 1;          // Price stop method (0-127)
INPUT float Envelopes_PriceStopLevel = 2;         // Price stop level
INPUT int Envelopes_TickFilterMethod = 32;        // Tick filter method
INPUT float Envelopes_MaxSpread = 4.0;            // Max spread to trade (pips)
INPUT short Envelopes_Shift = 0;                  // Shift
INPUT float Envelopes_OrderCloseLoss = 80;        // Order close loss
INPUT float Envelopes_OrderCloseProfit = 80;      // Order close profit
INPUT int Envelopes_OrderCloseTime = -30;         // Order close time in mins (>0) or bars (<0)
INPUT_GROUP("Envelopes strategy: Envelopes indicator params");
INPUT int Envelopes_Indi_Envelopes_MA_Period = 22;                             // Period
INPUT int Envelopes_Indi_Envelopes_MA_Shift = 0;                               // MA Shift
INPUT ENUM_MA_METHOD Envelopes_Indi_Envelopes_MA_Method = (ENUM_MA_METHOD)2;   // MA Method
INPUT ENUM_APPLIED_PRICE Envelopes_Indi_Envelopes_Applied_Price = PRICE_OPEN;  // Applied Price
INPUT float Envelopes_Indi_Envelopes_Deviation = 0.2f;                         // Deviation
INPUT int Envelopes_Indi_Envelopes_Shift = 0;                                  // Shift

// Structs.

// Defines struct with default user strategy values.
struct Stg_Envelopes_Params_Defaults : StgParams {
  Stg_Envelopes_Params_Defaults()
      : StgParams(::Envelopes_SignalOpenMethod, ::Envelopes_SignalOpenFilterMethod, ::Envelopes_SignalOpenLevel,
                  ::Envelopes_SignalOpenBoostMethod, ::Envelopes_SignalCloseMethod, ::Envelopes_SignalCloseFilter,
                  ::Envelopes_SignalCloseLevel, ::Envelopes_PriceStopMethod, ::Envelopes_PriceStopLevel,
                  ::Envelopes_TickFilterMethod, ::Envelopes_MaxSpread, ::Envelopes_Shift) {
    Set(STRAT_PARAM_LS, Envelopes_LotSize);
    Set(STRAT_PARAM_OCL, Envelopes_OrderCloseLoss);
    Set(STRAT_PARAM_OCP, Envelopes_OrderCloseProfit);
    Set(STRAT_PARAM_OCT, Envelopes_OrderCloseTime);
    Set(STRAT_PARAM_SOFT, Envelopes_SignalOpenFilterTime);
  }
};

#ifdef __config__
// Loads pair specific param values.
#include "config/H1.h"
#include "config/H4.h"
#include "config/H8.h"
#include "config/M1.h"
#include "config/M15.h"
#include "config/M30.h"
#include "config/M5.h"
#endif

class Stg_Envelopes : public Strategy {
 public:
  Stg_Envelopes(StgParams &_sparams, TradeParams &_tparams, ChartParams &_cparams, string _name = "")
      : Strategy(_sparams, _tparams, _cparams, _name) {}

  static Stg_Envelopes *Init(ENUM_TIMEFRAMES _tf = NULL) {
    // Initialize strategy initial values.
    Stg_Envelopes_Params_Defaults stg_env_defaults;
    StgParams _stg_params(stg_env_defaults);
#ifdef __config__
    SetParamsByTf<StgParams>(_stg_params, _tf, stg_env_m1, stg_env_m5, stg_env_m15, stg_env_m30, stg_env_h1, stg_env_h4,
                             stg_env_h8);
#endif
    // Initialize indicator.
    // Initialize Strategy instance.
    ChartParams _cparams(_tf, _Symbol);
    TradeParams _tparams;
    Strategy *_strat = new Stg_Envelopes(_stg_params, _tparams, _cparams, "Envelopes");
    return _strat;
  }

  /**
   * Event on strategy's init.
   */
  void OnInit() {
    IndiEnvelopesParams _indi_params(::Envelopes_Indi_Envelopes_MA_Period, ::Envelopes_Indi_Envelopes_MA_Shift,
                                     ::Envelopes_Indi_Envelopes_MA_Method, ::Envelopes_Indi_Envelopes_Applied_Price,
                                     ::Envelopes_Indi_Envelopes_Deviation, ::Envelopes_Indi_Envelopes_Shift);
    _indi_params.SetTf(Get<ENUM_TIMEFRAMES>(STRAT_PARAM_TF));
    SetIndicator(new Indi_Envelopes(_indi_params));
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    Indi_Envelopes *_indi = GetIndicator();
    Chart *_chart = (Chart *)_indi;
    bool _result =
        _indi.GetFlag(INDI_ENTRY_FLAG_IS_VALID, _shift) && _indi.GetFlag(INDI_ENTRY_FLAG_IS_VALID, _shift + 1);
    if (!_result) {
      // Returns false when indicator data is not valid.
      return false;
    }
    IndicatorSignal _signals = _indi.GetSignals(4, _shift);
    switch (_cmd) {
      // Buy: price crossed upper line in the last 3 bars.
      case ORDER_TYPE_BUY: {
        // Price value was lower than the lower LINE.
        double lowest_price = fmin3(_chart.GetLow(_shift), _chart.GetLow(_shift + 1), _chart.GetLow(_shift + 2));
        _result = (lowest_price < fmax3(_indi[_shift][(int)LINE_LOWER], _indi[_shift + 1][(int)LINE_LOWER],
                                        _indi[_shift + 2][(int)LINE_LOWER]));
        _result &= _indi.IsIncreasing(1);
        _result &= _indi.IsIncByPct(_level, 0, 0, 3);
        _result &= _method > 0 ? _signals.CheckSignals(_method) : _signals.CheckSignalsAll(-_method);
        break;
      }
      // Sell: price crossed lower line in the last 3 bars.
      case ORDER_TYPE_SELL: {
        // Price value was higher than the upper LINE.
        double highest_price = fmin3(_chart.GetHigh(_shift), _chart.GetHigh(_shift + 1), _chart.GetHigh(_shift + 2));
        _result = (highest_price > fmin3(_indi[_shift][(int)LINE_UPPER], _indi[_shift + 1][(int)LINE_UPPER],
                                         _indi[_shift + 2][(int)LINE_UPPER]));
        _result &= _indi.IsDecreasing(1);
        _result &= _indi.IsDecByPct(-_level, 0, 0, 3);
        _result &= _method > 0 ? _signals.CheckSignals(_method) : _signals.CheckSignalsAll(-_method);
        break;
      }
    }
    return _result;
  }

  /**
   * Check strategy's closing signal.
   */
  bool SignalClose(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0) {
    return SignalOpen(Order::NegateOrderType(_cmd), _method, _level);
  }
};
