/*
 * @file
 * Defines default strategy parameter values for the given timeframe.
 */

// Defines indicator's parameter values for the given pair symbol and timeframe.
struct Indi_Envelopes_Params_M5 : Indi_Envelopes_Params {
  Indi_Envelopes_Params_M5() : Indi_Envelopes_Params(indi_envelopes_defaults, PERIOD_M5) { shift = 0; }
} indi_envelopes_m5;

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_Envelopes_Params_M5 : StgParams {
  // Struct constructor.
  Stg_Envelopes_Params_M5() : StgParams(stg_envelopes_defaults) {
    lot_size = 0;
    signal_open_method = 0;
    signal_open_filter = 1;
    signal_open_level = 0;
    signal_open_boost = 0;
    signal_close_method = 0;
    signal_close_level = 0;
    price_limit_method = 0;
    price_limit_level = 2;
    tick_filter_method = 1;
    max_spread = 0;
  }
} stg_envelopes_m5;
