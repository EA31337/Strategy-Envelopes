//+------------------------------------------------------------------+
//|                 EA31337 - multi-strategy advanced trading robot. |
//|                       Copyright 2016-2017, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/*
    This file is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// Properties.
#property strict

/**
 * @file
 * Implementation of Envelopes Strategy based on the Envelopes indicator.
 *
 * @docs
 * - https://docs.mql4.com/indicators/iEnvelopes
 * - https://www.mql5.com/en/docs/indicators/iEnvelopes
 */

// Includes.
#include <EA31337-classes\Strategy.mqh>
#include <EA31337-classes\Strategies.mqh>

// User inputs.
#ifdef __input__ input #endif string __Envelopes_Parameters__ = "-- Settings for the Envelopes indicator --"; // >>> ENVELOPES <<<
#ifdef __input__ input #endif int Envelopes_MA_Period = 32; // Period
#ifdef __input__ input #endif double Envelopes_MA_Period_Ratio = 1.0; // Period ratio between timeframes (0.5-1.5)
#ifdef __input__ input #endif ENUM_MA_METHOD Envelopes_MA_Method = 2; // MA Method
#ifdef __input__ input #endif int Envelopes_MA_Shift = 2; // MA Shift
#ifdef __input__ input #endif ENUM_APPLIED_PRICE Envelopes_Applied_Price = 1; // Applied Price
#ifdef __input__ input #endif double Envelopes_Deviation = 0.4; // Deviation for M1
#ifdef __input__ input #endif double Envelopes_Deviation_Ratio = 0.6; // Deviation ratio between timeframes (0.5-1.5)
#ifdef __input__ input #endif int Envelopes_Shift = 0; // Shift
#ifdef __input__ input #endif int Envelopes_Shift_Far = 0; // Shift Far
#ifdef __input__ input #endif int Envelopes_SignalLevel = 0; // Signal level
#ifdef __input__ input #endif int Envelopes_SignalMethod = 93; // Signal method for M1 (-127-127)

class Envelopes: public Strategy {
protected:

  double envelopes[H1][FINAL_ENUM_INDICATOR_INDEX][FINAL_LINE_ENTRY];
  int       open_method = EMPTY;    // Open method.
  double    open_level  = 0.0;     // Open level.

    public:

  /**
   * Update indicator values.
   */
  bool Update(int tf = EMPTY) {
    // Calculates the Envelopes indicator.
    // envelopes_deviation = Envelopes30_Deviation;
    // switch (period) {
    //   case M1: envelopes_deviation = Envelopes1_Deviation; break;
    //   case M5: envelopes_deviation = Envelopes5_Deviation; break;
    //  case M15: envelopes_deviation = Envelopes15_Deviation; break;
    //  case M30: envelopes_deviation = Envelopes30_Deviation; break;
    //}
    ratio = 30 / fmax(Envelopes_MA_Period_Ratio, NEAR_ZERO) / 30 / 30 * tf;
    ratio2 = 30 / fmax(Envelopes_Deviation_Ratio, NEAR_ZERO) / 30 / 30 * tf;
    for (int i = 0; i < FINAL_ENUM_INDICATOR_INDEX; i++) {
      envelopes[index][i][MODE_MAIN] = iEnvelopes(symbol, tf, (int) (Envelopes_MA_Period * ratio), Envelopes_MA_Method, Envelopes_MA_Shift, Envelopes_Applied_Price, Envelopes_Deviation * ratio2, MODE_MAIN,  i + Envelopes_Shift);
      envelopes[index][i][UPPER]     = iEnvelopes(symbol, tf, (int) (Envelopes_MA_Period * ratio), Envelopes_MA_Method, Envelopes_MA_Shift, Envelopes_Applied_Price, Envelopes_Deviation * ratio2, UPPER, i + Envelopes_Shift);
      envelopes[index][i][LOWER]     = iEnvelopes(symbol, tf, (int) (Envelopes_MA_Period * ratio), Envelopes_MA_Method, Envelopes_MA_Shift, Envelopes_Applied_Price, Envelopes_Deviation * ratio2, LOWER, i + Envelopes_Shift);
    }
    success = (bool) envelopes[index][CURR][MODE_MAIN];
    if (VerboseDebug) PrintFormat("Envelopes M%d: %s", tf, Arrays::ArrToString3D(envelopes, ",", Digits));
  }

  /**
   * Check if Envelopes indicator is on sell.
   *
   * @param
   *   cmd (int) - type of trade order command
   *   period (int) - period to check for
   *   signal_method (int) - signal method to use by using bitwise AND operation
   *   signal_level (double) - signal level to consider the signal
   */
  bool Signal(int cmd, ENUM_TIMEFRAMES tf = PERIOD_M1, int signal_method = EMPTY, double signal_level = EMPTY) {
    bool result = FALSE; int period = Timeframe::TfToIndex(tf);
    UpdateIndicator(S_ENVELOPES, tf);
    if (signal_method == EMPTY) signal_method = GetStrategySignalMethod(S_ENVELOPES, tf, 0);
    if (signal_level == EMPTY)  signal_level  = GetStrategySignalLevel(S_ENVELOPES, tf, 0.0);
    switch (cmd) {
      case OP_BUY:
        result = Low[CURR] < envelopes[period][CURR][LOWER] || Low[PREV] < envelopes[period][CURR][LOWER]; // price low was below the lower band
        // result = result || (envelopes[period][CURR][MODE_MAIN] > envelopes[period][FAR][MODE_MAIN] && Open[CURR] > envelopes[period][CURR][UPPER]);
        if ((signal_method &   1) != 0) result &= Open[CURR] > envelopes[period][CURR][LOWER]; // FIXME
        if ((signal_method &   2) != 0) result &= envelopes[period][CURR][MODE_MAIN] < envelopes[period][PREV][MODE_MAIN];
        if ((signal_method &   4) != 0) result &= envelopes[period][CURR][LOWER] < envelopes[period][PREV][LOWER];
        if ((signal_method &   8) != 0) result &= envelopes[period][CURR][UPPER] < envelopes[period][PREV][UPPER];
        if ((signal_method &  16) != 0) result &= envelopes[period][CURR][UPPER] - envelopes[period][CURR][LOWER] > envelopes[period][PREV][UPPER] - envelopes[period][PREV][LOWER];
        if ((signal_method &  32) != 0) result &= Ask < envelopes[period][CURR][MODE_MAIN];
        if ((signal_method &  64) != 0) result &= Close[CURR] < envelopes[period][CURR][UPPER];
        //if ((signal_method & 128) != 0) result &= Ask > Close[PREV];
        break;
      case OP_SELL:
        result = High[CURR] > envelopes[period][CURR][UPPER] || High[PREV] > envelopes[period][CURR][UPPER]; // price high was above the upper band
        // result = result || (envelopes[period][CURR][MODE_MAIN] < envelopes[period][FAR][MODE_MAIN] && Open[CURR] < envelopes[period][CURR][LOWER]);
        if ((signal_method &   1) != 0) result &= Open[CURR] < envelopes[period][CURR][UPPER]; // FIXME
        if ((signal_method &   2) != 0) result &= envelopes[period][CURR][MODE_MAIN] > envelopes[period][PREV][MODE_MAIN];
        if ((signal_method &   4) != 0) result &= envelopes[period][CURR][LOWER] > envelopes[period][PREV][LOWER];
        if ((signal_method &   8) != 0) result &= envelopes[period][CURR][UPPER] > envelopes[period][PREV][UPPER];
        if ((signal_method &  16) != 0) result &= envelopes[period][CURR][UPPER] - envelopes[period][CURR][LOWER] > envelopes[period][PREV][UPPER] - envelopes[period][PREV][LOWER];
        if ((signal_method &  32) != 0) result &= Ask > envelopes[period][CURR][MODE_MAIN];
        if ((signal_method &  64) != 0) result &= Close[CURR] > envelopes[period][CURR][UPPER];
        //if ((signal_method & 128) != 0) result &= Ask < Close[PREV];
        break;
    }
    result &= signal_method <= 0 || Convert::ValueToOp(curr_trend) == cmd;
    if (VerboseTrace && result) {
      PrintFormat("%s:%d: Signal: %d/%d/%d/%g", __FUNCTION__, __LINE__, cmd, tf, signal_method, signal_level);
    }
    return result;
  }
};
