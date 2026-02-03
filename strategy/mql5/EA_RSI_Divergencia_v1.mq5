//+------------------------------------------------------------------+
//|   RSI Divergence Detector - MT5                                   |
//|   Detecta divergencia alcista con RSI (modo humano)               |
//+------------------------------------------------------------------+
#property strict

input int    RSI_Period      = 14;
input int    RSI_Oversold    = 30;
input int    LookbackBars    = 60;
input double PriceTolerance = 20; // en puntos

int rsiHandle;

//+------------------------------------------------------------------+
int OnInit()
{
   rsiHandle = iRSI(_Symbol, _Period, RSI_Period, PRICE_CLOSE);

   if(rsiHandle == INVALID_HANDLE)
   {
      Print("❌ Error creando RSI");
      return(INIT_FAILED);
   }

   Print("✅ EA iniciado correctamente");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   IndicatorRelease(rsiHandle);
}

//+------------------------------------------------------------------+
void OnTick()
{
   static datetime lastBarTime = 0;
   datetime currentBarTime = iTime(_Symbol, _Period, 0);

   if(currentBarTime == lastBarTime)
      return;

   lastBarTime = currentBarTime;

   DetectBullishDivergence();
}

//+------------------------------------------------------------------+
void DetectBullishDivergence()
{
   double rsi[];
   ArraySetAsSeries(rsi, true);

   if(CopyBuffer(rsiHandle, 0, 0, LookbackBars, rsi) <= 0)
   {
      Print("❌ Error copiando RSI");
      return;
   }

   int firstRSI = -1;
   int secondRSI = -1;

   // Buscar DOS mínimos en sobreventa
   for(int i = 2; i < LookbackBars - 2; i++)
   {
      if(rsi[i] <= RSI_Oversold &&
         rsi[i] < rsi[i-1] &&
         rsi[i] < rsi[i+1])
      {
         if(firstRSI == -1)
            firstRSI = i;
         else
         {
            secondRSI = i;
            break;
         }
      }
   }

   if(firstRSI == -1 || secondRSI == -1)
      return;

   double price1 = iLow(_Symbol, _Period, firstRSI);
   double price2 = iLow(_Symbol, _Period, secondRSI);

   double tolerance = PriceTolerance * _Point;

   // Divergencia ALCISTA (modo humano)
   if(price2 <= price1 + tolerance &&
      rsi[secondRSI] > rsi[firstRSI])
   {
      string msg = "📈 DIVERGENCIA ALCISTA RSI\n"
                   "TF: " + EnumToString(_Period) +
                   "\nPrecio 1: " + DoubleToString(price1, _Digits) +
                   "\nPrecio 2: " + DoubleToString(price2, _Digits) +
                   "\nRSI 1: " + DoubleToString(rsi[firstRSI], 2) +
                   "\nRSI 2: " + DoubleToString(rsi[secondRSI], 2);

      Print(msg);
      Alert(msg);
   }
}
