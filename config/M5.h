/**
 * @file
 * Defines default strategy parameter values for the given timeframe.
 */

// Defines indicator's parameter values for the given pair symbol and timeframe.
struct Indi_Envelopes_Params_M5 : IndiEnvelopesParams {
  Indi_Envelopes_Params_M5() : IndiEnvelopesParams(indi_env_defaults, PERIOD_M5) {
    applied_price = (ENUM_APPLIED_PRICE)4;
    deviation = 0.1;
    ma_method = (ENUM_MA_METHOD)1;
    ma_period = 24;
    ma_shift = 4;
    shift = 0;
  }
} indi_env_m5;

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_Envelopes_Params_M5 : StgParams {
  // Struct constructor.
  Stg_Envelopes_Params_M5() : StgParams(stg_env_defaults) {
    lot_size = 0;
    signal_open_method = 2;
    signal_open_level = (float)0.0;
    signal_open_boost = 0;
    signal_close_method = 2;
    signal_close_level = (float)0;
    price_profit_method = 60;
    price_profit_level = (float)6;
    price_stop_method = 60;
    price_stop_level = (float)6;
    tick_filter_method = 1;
    max_spread = 0;
  }
} stg_env_m5;
