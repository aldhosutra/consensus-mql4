//+------------------------------------------------------------------+
//|                                                    Consensus.mq4 |
//|         Copyright © 2019, Aldo Suhartono Putra                   |
//| Metatrader 4 indicator which combines several custom technical   |
//| indicators to signal up or down price movements and calculates   |
//| the signal accuracy of the next n candles historically over a    |
//| certain period of time                                           |
//+------------------------------------------------------------------+

#include <WinUser32.mqh>
#property copyright "Copyright © 2019, Aldo Suhartono Putra"
#property link      "mailto:aldhosutra@gmail.com"

#property indicator_chart_window
#property indicator_buffers 4
#property indicator_color1 LimeGreen
#property indicator_color2 Red
#property indicator_color3 White
#property indicator_color4 Yellow

enum ExpirySet {
   M1 = 1, // 1 Minute
   M2 = 2, // 2 Minute
   M3 = 3, // 3 Minute
   M4 = 4, // 4 Minute
   M5 = 5, // 5 Minute
   M15 = 15, // 15 Minute
   M30 = 30, // 30 Minute
   M45 = 45, // 45 Minute
   M60 = 60, // 60 Minute
   M75 = 75, // 75 Minute
   M90 = 90, // 90 Minute
   M105 = 105, // 105 Minute
   M120 = 120, // 120 Minute
   M135 = 135, // 135 Minute
   M150 = 150, // 150 Minute
   M165 = 165, // 165 Minute
   M180 = 180, // 180 Minute
   M195 = 195, // 195 Minute
   M210 = 210, // 210 Minute
};

extern string Hotkey_Setting         ="//////////////////////////////////////////////////////////";
extern string HotkeyDescription      = "Call: CTRL + Alt + P+(KeyIndex); Put: CTRL + SHIFT + Alt + P+(KeyIndex); Default KeyIndex=1 (Q)";
extern bool   HotKeyTrigger          = false;
extern int    HotKeyLoopIndex        = 1;
extern int    KeyIndex               = 1;

extern string IQOption_Setting       = "//////////////////////////////////////////////////////////";
extern bool   ConnectIQAPI           = false;
extern string IQ_Username            = "Username";
extern string IQ_Password            = "Password";
extern int    PositionSize           = 1;

extern string Signal_Alert_Setting   ="//////////////////////////////////////////////////////////";
extern bool SoundAlert               = true;
extern bool EmailAlert               = false;

extern string Prep_Alert_Setting     ="//////////////////////////////////////////////////////////";
extern bool PrepSoundAlert           = false;
extern bool PrepEmailAlert           = false;

//Signaling setting
extern string Indicator_Signaling_Setting="//////////////////////////////////////////////////////////";
extern bool  ReverseMode             = false;
input ExpirySet   expiryConfig       = M1;
extern bool  SafeStrikePriceMode     = false;
extern int   StrikePriceIndex        = 10;

//Global Statistics setting
extern string Indicator_Status_Setting="//////////////////////////////////////////////////////////";
extern bool  DisplayStatIndicator    = true;
extern bool  CalculateOnlyOneDay     = false;
extern bool  NotQualifiedSignalNotify= false;
extern int   MinQualifiedWinRate     = 56;
extern int   MaxQualifiedConsLose    = 20;
extern int   NotSafeIndex            = 10;
extern int   ConsecutiveDelayIndex   = 0;
extern int   StatCorner              = 1;
extern bool  VerboseMode             = false;

extern string Yesterday_Status_Setting="//////////////////////////////////////////////////////////";
extern bool  DisplayYesterdayStat    = true;
extern bool  DisplayAdditionalMode   = false; // 1=Win-Lose-WinRate; 2=Consecutive Win & Lose - Not Safe Win & Lose; 3=Everything.
extern bool  skipNotValidRow         = true;
extern int   YesterdayCount          = 10;
extern int   RowPerColoumn           = 36;

//Neural Network Setting
extern string Neural_Network_Setting   ="//////////////////////////////////////////////////////////";
extern bool   UseNeuralNetwork         = false;

//Stochastic Setting
extern string Stochastic_Filter_Setting="//////////////////////////////////////////////////////////";
extern bool   UseStochFilter           = false;
extern bool   UseOBOSFilter            = false;
extern int    KPeriod                  = 5;
extern int    DPeriod                  = 3;
extern int    Slowing                  = 3;

extern string MA_Cross_Setting="//////////////////////////////////////////////////////////";
extern bool  UseMACross              = true;
extern int   FastMA_Mode             = 1; //0=sma, 1=ema, 2=smma, 3=lwma, 4=lsma
extern int   FastMA_Period           = 4;
extern int   FastPriceMode           = 1; //0=close, 1=open, 2=high, 3=low, 4=median(high+low)/2, 5=typical(high+low+close)/3, 6=weighted(high+low+close+close)/4
extern int   SlowMA_Mode             = 1; //0=sma, 1=ema, 2=smma, 3=lwma, 4=lsma
extern int   SlowMA_Period           = 4;
extern int   SlowPriceMode           = 0; //0=close, 1=open, 2=high, 3=low, 4=median(high+low)/2, 5=typical(high+low+close)/3, 6=weighted(high+low+close+close)/4

//Bill William ZoneTrade Filter Setting
extern string Bill_William_ZoneTrade_Filter_Setting="//////////////////////////////////////////////////////////";
extern bool   useBWZoneTrade         = false;
extern int    ZoneMode               = 1;
extern string modeDesc               = "1 = trend (trade in red or green), 2 = reversal (trade in grey)";

//Heikin Ashi setting
extern string Heikin_Ashi_Setting    ="//////////////////////////////////////////////////////////";
extern bool   UseHeikinAshi          = false;

//Heikin Ashi setting
extern string MACD_Setting             ="//////////////////////////////////////////////////////////";
extern bool   UseMACD                  = false;

//fractal setting
extern string High_Low_Filter_Setting="//////////////////////////////////////////////////////////";
extern bool   UseHighLowFilter       = true;
extern bool   RepaintMode            = false;
extern int    HighLowToMADistance    = 0;
extern int    HighLowPeriod          = 25;
extern int    PriceHigh              = PRICE_HIGH;
extern int    PriceLow               = PRICE_LOW;

//pivot point setting
extern string           Pivot_Point_Setting ="//////////////////////////////////////////////////////////";
extern bool             UsePivotFilter      = false;
extern ENUM_TIMEFRAMES  TimePeriod          = PERIOD_D1;
extern bool             PivotMode           = true;
extern bool             FibonacciMode       = true;
extern bool             MidpointMode        = true;
extern int              PivotLevelRange     = 5;
extern bool             DrawPivotLevel      = false;
extern int              CountPeriods        = 20;

//bolinger setting
extern string Bollinger_Band_Default_Filter_Setting="//////////////////////////////////////////////////////////";
extern bool   UseBBDefault           = false;
extern bool   BBTrendMode            = false;
extern int    BBPeriod               = 20;
extern int    StdDeviation           = 2;
extern double OversoldBBLevel        = 0.2;
extern double OverboughtBBLevel      = 0.8;

//MA Trend setting
extern string MA_Trend_Filter_Setting="//////////////////////////////////////////////////////////";
extern bool   UseMATrendFilter       = false;
extern int    TrendFastPeriod        = 34;
extern int    TrendSlowPeriod        = 50;

//RSI Setting
extern string RSI_Filter_Setting     ="//////////////////////////////////////////////////////////";
extern bool   UseRSIFilter           = false;
extern int    RSIPeriod              = 5;
extern int    OverBoughtLevel        = 70;
extern int    OverSoldLevel          = 30;

//CandlePattern setting
extern string Candle_Pattern_Setting ="//////////////////////////////////////////////////////////";
extern bool   UseCandleFilter        = false;
extern int    CandleToMADistance     = 0;
extern bool   UseHammer              = false;
extern bool   UseShootingStar        = false;
extern bool   UseEngulfing           = false;
extern bool   UseDoji                = false;
extern bool   UsePinbar              = false;
extern bool   Use3Outside            = false;
extern bool   Use3Inside             = false;
extern bool   UseHarami              = false;
extern bool   UseStar                = false;
extern bool   UsePiercingLine        = false;
extern bool   UseDarkCloud           = false;

#import "shell32.dll"

int ShellExecuteW(
    int hwnd,
    string Operation,
    string File,
    string Parameters,
    string Directory,
    int ShowCmd
);
#import

#import "wininet.dll"
int InternetOpenW(
    string     sAgent,
    int        lAccessType,
    string     sProxyName="",
    string     sProxyBypass="",
    int     lFlags=0
);
int InternetOpenUrlW(
    int     hInternetSession,
    string     sUrl, 
    string     sHeaders="",
    int     lHeadersLength=0,
    uint     lFlags=0,
    int     lContext=0 
);
int InternetReadFile(
    int     hFile,
    uchar  &   sBuffer[],
    int     lNumBytesToRead,
    int&     lNumberOfBytesRead
);
int InternetCloseHandle(
    int     hInet
);       
#import

#define INTERNET_FLAG_RELOAD            0x80000000
#define INTERNET_FLAG_NO_CACHE_WRITE    0x04000000
#define INTERNET_FLAG_PRAGMA_NOCACHE    0x00000100

int hSession_IEType;
int hSession_Direct;
int Internet_Open_Type_Preconfig = 0;
int Internet_Open_Type_Direct = 1;

int hSession(bool Direct)
{
    string InternetAgent = "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; Q312461)";
    
    if (Direct) 
    { 
        if (hSession_Direct == 0)
        {
            hSession_Direct = InternetOpenW(InternetAgent, Internet_Open_Type_Direct, "0", "0", 0);
        }
        
        return(hSession_Direct); 
    }
    else 
    {
        if (hSession_IEType == 0)
        {
           hSession_IEType = InternetOpenW(InternetAgent, Internet_Open_Type_Preconfig, "0", "0", 0);
        }
        
        return(hSession_IEType); 
    }
}

string httpGET(string strUrl)
{
   int handler = hSession(false);
   int response = InternetOpenUrlW(handler, strUrl, NULL, 0,
        INTERNET_FLAG_NO_CACHE_WRITE |
        INTERNET_FLAG_PRAGMA_NOCACHE |
        INTERNET_FLAG_RELOAD, 0);
   if (response == 0) 
        return("false");
        
   uchar ch[100]; string toStr=""; int dwBytes, h=-1;
   while(InternetReadFile(response, ch, 100, dwBytes)) 
  {
    if (dwBytes<=0) break; toStr=toStr+CharArrayToString(ch, 0, dwBytes);
  }
  
  InternetCloseHandle(response);
  return toStr;
}

void httpOpen(string strUrl)
{
  Shell32::ShellExecuteW(0, "open", strUrl, "", "", 3);
}

//--- Neural Networks Parameter Initialization

   double w[55][1] = {0.39918914,0.30628526,0.4520514,0.18022804,-0.4192954,-20.317705,8.598318,6.539786,1.3861573,2.2943826,-0.7327864,-2.0424726,-1.6425737,-1.7357156,-2.270176,-0.44706786,-2.8150766,0.58582836,0.8303422,1.2874321,-0.46808055,-1.0052648,-0.5780407,-0.3651842,-0.33284408,-0.8991183,-1.0647347,-0.741877,-0.5471473,-0.4494761,3.4222677,-6.1190796,-0.81252414,2.1566968,0.5311871,7.278836,-14.919421,2.9766705,2.8386617,-3.2106676,-2.2451084,1.7868838,4.6651797,0.41201544,-0.18316728,1.3227417,-3.9406457,-0.7190106,-1.3257453,-1.7909725,27.08016,-6.3075485,-4.884911,1.9218698,0.29445136};
   
   double b[1] = {1.0168726};
   
   double neuronInput[55];
   
//--- Init End

double CrossUp[];
double CrossDown[];
double DrawWin[];
double DrawLose[];
bool Q_Buffer=false;
int currentDate=0;
int tickDate=0;
double last_signal=0;
double last_action=OP_BUY;
double AC_0;
double AC_1;
double AO_0;
double AO_1;
double dayRange = 0.0;
int winOnExpiry[];
int loseOnExpiry[];
int consWinOnExpiry[];
int consLoseOnExpiry[];
int bufferMaxWinOnExpiry[];
int bufferMaxLoseOnExpiry[];
int MaxWinDelayOnExpiry[];
int MaxLoseDelayOnExpiry[];
int MaxLoseOnExpiry[];
int MaxWinOnExpiry[];
int ExpiryCounter = 0;
int expiryCandle;

//+------------------------------------------------------------------+
//| Statistic Variable Declaration                                   |
//+------------------------------------------------------------------+
int totalTrade=0;
bool isUpTrade=false;
bool isDownTrade=false;
bool Prep_isUpTrade=false;
bool Prep_isDownTrade=false;
int sumWin;
int sumLose;
int bufferMaxWin;
int MaxWin;
int bufferMaxLose;
int MaxLose;
string MaxWinDate;
string MaxLoseDate;
int MaxWinDelayBuffer;
int MaxLoseDelayBuffer;
int tmpExpiry;
int notSafeWinUp;
int notSafeWinDown;
int notSafeLoseUp;
int notSafeLoseDown;

//+------------------------------------------------------------------+
//| Pivot Point Variable Declaration                                 |
//+------------------------------------------------------------------+
int              shiftBars; 
string           period;
datetime         timestart, timeend;
double           PPOpen, PPClose, PPHigh, PPLow;
double           /*Pivot Levels*/ PP, R1, R2, R3, S1, S2, S3, M0, M1, M2, M3, M4, M5, /*Fibo Level*/ f214, f236, f382, f50, f618, f764, f786;

bool             PlotPivots;
bool             PlotFibots;
bool             PlotMidpoints;
   
bool             PlotPivotLabels=true;
bool             PlotPivotPrices=true;
ENUM_LINE_STYLE  StylePivots=STYLE_SOLID;
int              WidthPivots=2;
color            ColorRes=clrRed;
color            ColorPP=clrGray;
color            ColorSup=clrGreen;
ENUM_LINE_STYLE  StyleMidpoints=STYLE_DASH;
int              WidthMidpoints=1;
color            ColorM35=clrRed;
color            ColorM02=clrGreen;
bool             PlotZones=false;
color            ColorBuyZone=clrLightGreen;
color            ColorSellZone=clrPink;
bool             PlotBorders=false;
ENUM_LINE_STYLE  StyleBorder=STYLE_SOLID;
int              WidthBorder=2;
color            ColorBorder=clrBlack;
bool             PlotFibotLabels=true;
bool             PlotFibotPrices=true;
ENUM_LINE_STYLE  StyleFibots1=STYLE_DOT;
ENUM_LINE_STYLE  StyleFibots2=STYLE_SOLID;
int              WidthFibots1=1;
int              WidthFibots2=1;
color            ColorFibots=clrDodgerBlue;
double           PivotLevelArray[20][2];

//+------------------------------------------------------------------+
//| Basic Function                                                   |
//+------------------------------------------------------------------+
bool isBuySignal (int i) {
   if (isUpMACD(i) && isOnPivotLevel(i) && isUpHeikinAshi(i) && isOversoldBB(i) && isMACrossUp(i) && isLowerFractal(i+HighLowToMADistance) && isRSIOverSold(i) && isUpTrend(i) && isBWGreenZone(i) && IsBuyPinbar(dayRange,i+CandleToMADistance-1) && isBulishCandle(i+CandleToMADistance-1) && isStochCrossUp(i) && isUpNeuralNetwork(i)) {return true;} else {return false;}
}

bool isSellSignal (int i) {
   if (isDownMACD(i) && isOnPivotLevel(i) && isDownHeikinAshi(i) && isOverboughtBB(i) && isMACrossDown(i) && isUpperFractal(i+HighLowToMADistance) && isRSIOverBought(i) && isDownTrend(i) && isBWRedZone(i) && IsSellPinbar(dayRange,i+CandleToMADistance-1) && isBearsihCandle(i+CandleToMADistance-1) && isStochCrossDown(i) && isDownNeuralNetwork(i)) {return true;} else {return false;}
}

void BuyHotkey(int index=1) {
   keybd_event(17, 0, 0, 0); // CTRL key down
   keybd_event(18, 0, 0, 0); // ALT key down
   keybd_event(80+index, 0, 0, 0); // Q (+index) key down
   keybd_event(80+index, 0, 2, 0); // Q (+index) key released
   keybd_event(18, 0, 2, 0); // ALT key released
   keybd_event(17, 0, 2, 0); // CTRL key released
}

void SellHotkey(int index=1) {
   keybd_event(17, 0, 0, 0); // CTRL key down
   keybd_event(16, 0, 0, 0); // SHIFT key down
   keybd_event(18, 0, 0, 0); // ALT key down
   keybd_event(80+index, 0, 0, 0); // Q (+index) key down
   keybd_event(80+index, 0, 2, 0); // Q (+index) key released
   keybd_event(18, 0, 2, 0); // ALT key released
   keybd_event(16, 0, 2, 0); // SHIFT key released
   keybd_event(17, 0, 2, 0); // CTRL key released
}

void testHotkey () {
   keybd_event(69, 0, 0, 0); // E down
   keybd_event(69, 0, 2, 0); // E up
}

int SleepXIndicators(int milli_seconds)
  {
   uint cont=0;
   uint startTime;
   int sleepTime=0;
   startTime = GetTickCount();
   while (cont<500000000)
     {
      cont++;
      sleepTime = (int)(GetTickCount()-startTime);
      if ( sleepTime >= milli_seconds ) break;
     }   
   return(sleepTime);
  }
  
void TimeCandle() {
   int min,sec;
   
   min=Time[0]+Period()*60-CurTime();
   sec=min%60;
   min=(min-sec)/60;
   
   Print ("Minute: "+min+", Second: "+sec);

}

double CallStrikePrice (int i) {
   if(SafeStrikePriceMode) { return (Open[i]-((StrikePriceIndex*(MathAbs(Open[i+1]-Close[i+1])))/100));} else {return Open[i];}
}
double PutStrikePrice (int i) { 
   if(SafeStrikePriceMode) { return (Open[i]+((StrikePriceIndex*(MathAbs(Open[i+1]-Close[i+1])))/100));} else {return Open[i];}
}

void winExpiryUpdater (int expiryIndex) {
   winOnExpiry[expiryIndex]++;
   bufferMaxWinOnExpiry[expiryIndex]++;
   if (MaxLoseDelayOnExpiry[expiryIndex]==0) {
      MaxLoseDelayOnExpiry[expiryIndex]=ConsecutiveDelayIndex;
      if (bufferMaxLoseOnExpiry[expiryIndex]>MaxLoseOnExpiry[expiryIndex]) {MaxLoseOnExpiry[expiryIndex]=bufferMaxLoseOnExpiry[expiryIndex]; bufferMaxLoseOnExpiry[expiryIndex]=0;} else {bufferMaxLoseOnExpiry[expiryIndex]=0;}
   } else {MaxLoseDelayOnExpiry[expiryIndex]--;}
}

void loseExpiryUpdater (int expiryIndex) {
   loseOnExpiry[expiryIndex]++;
   bufferMaxLoseOnExpiry[expiryIndex]++;
   if (MaxWinDelayOnExpiry[expiryIndex]==0) {
      MaxWinDelayOnExpiry[expiryIndex]=ConsecutiveDelayIndex;
      if (bufferMaxWinOnExpiry[expiryIndex]>MaxWinOnExpiry[expiryIndex]) {MaxWinOnExpiry[expiryIndex]=bufferMaxWinOnExpiry[expiryIndex]; bufferMaxWinOnExpiry[expiryIndex]=0;} else {bufferMaxWinOnExpiry[expiryIndex]=0;}
   } else {MaxWinDelayOnExpiry[expiryIndex]--;}
}

void NNMatmul (double& weights[][], double& inputs[], double& resultContainer[]) {
   if ((ArrayRange(weights,1) == ArraySize(resultContainer)) && (ArraySize(inputs) == ArrayRange(weights,0))){
      int wIdx;
      int inpIdx;
      double resultCalc = 0;
      for (wIdx=0; wIdx<=ArrayRange(weights,1)-1; wIdx++) {
            for (inpIdx=0; inpIdx<=ArraySize(inputs)-1; inpIdx++) {
               resultCalc += inputs[inpIdx]*weights[inpIdx][wIdx];
            }
            resultContainer[wIdx] = resultCalc;
            resultCalc = 0;
         }
   } else if (ArrayRange(weights,1) != ArraySize(resultContainer)) {
       Print("Size of Weight Second Layer Size (" +IntegerToString(ArrayRange(weights,1))+ ") and Expected Result Size (" +IntegerToString(ArraySize(resultContainer))+ ")not same, Multiplication cannot proceed, Change Your Array Size!");
   } else if (ArraySize(inputs) != ArrayRange(weights,0)) {
       Print("Size of Weight First Layer Size (" +IntegerToString(ArrayRange(weights,0))+ ") and Input Layer Size (" +IntegerToString(ArraySize(inputs))+ ")not same, Multiplication cannot proceed, Change Your Array Size!");   
   }
}

void NNMatadd (double& bias[], double& inputs[], double& resultContainer[]) {
   if (ArraySize(bias) == ArraySize(inputs)){
         int bIdx;
         for (bIdx=0; bIdx<=ArraySize(bias)-1;bIdx++) {
            resultContainer[bIdx] = inputs[bIdx] + bias[bIdx];
         }
   } else {
         Print("Size of Input Layer (" +IntegerToString(ArraySize(inputs))+ ") and Bias (" +IntegerToString(ArraySize(bias))+ ")not same, Addition cannot proceed");
   }
}

void NNRelu (double& inputs[]) {
   int reluID;
   for (reluID=0; reluID<=ArraySize(inputs)-1;reluID++) {
      inputs[reluID] = MathMax(0,inputs[reluID]);
   }
}

double NNLogistic (double inputs) {
   return exp(inputs)/(exp(inputs)+1);
}

double NNLogits (double& inputs[]) {
   
   double inProcessContainer[1];
   /*double FirstLayer[36];
   double SecondLayer[36];
   double ThirdLayer[36];
   double FourthLayer[36];
   double FifthLayer[36];
   double logitsOutput[1];
   
   NNMatmul(weight_h0,inputs,FirstLayer);
   NNMatadd(bias_h0,FirstLayer,FirstLayer);
   NNRelu(FirstLayer);
   
   NNMatmul(weight_h1,FirstLayer,SecondLayer);
   NNMatadd(bias_h1,SecondLayer,SecondLayer);
   NNRelu(SecondLayer);
   
   NNMatmul(weight_h2,SecondLayer,ThirdLayer);
   NNMatadd(bias_h2,ThirdLayer,ThirdLayer);
   NNRelu(ThirdLayer);
   
   NNMatmul(weight_h3,ThirdLayer,FourthLayer);
   NNMatadd(bias_h3,FourthLayer,FourthLayer);
   NNRelu(FourthLayer);
   
   NNMatmul(weight_h4,FourthLayer,FifthLayer);
   NNMatadd(bias_h4,FifthLayer,FifthLayer);
   NNRelu(FifthLayer);
   
   NNMatmul(weight_output,FifthLayer,logitsOutput);
   NNMatadd(bias_output,logitsOutput,logitsOutput);
   NNRelu(logitsOutput);*/
   
   //Print("logits = " + logitsOutput[0]);
   
   NNMatmul(w,inputs,inProcessContainer);
   NNMatadd(b,inProcessContainer,inProcessContainer);
   
   return inProcessContainer[0];
}

int NeuronOutput(double& inputs[]) {
   double logistics;
   double logits;
   logits = NNLogits(inputs);
   logistics = NNLogistic(logits);
   // Print("Logits = " + DoubleToString(logits) + ", Logistics = " + DoubleToString(logistics));
   
   if (logistics > 0.5) {return 1;}
   else {return 0;}
}

//+---------------------------------------------------------------------------+
//| Neural Signal Input Data Function                                         |
//| There are 11 different function                                           |
//| WriteDatasetToCSV() is to put all value to csv (ClassType: Call=1, Put=0) |
//+---------------------------------------------------------------------------+
void WriteDatasetToCSV(int fileHandler, int i, int ClassType) {
  FileWrite(fileHandler,Symbol()+"-M"+Period(),PivotIndex(i),PivotIndex(i+1),PivotIndex(i+2),PivotIndex(i+3),PivotIndex(i+4),OpenCloseDevIndex(i),OpenCloseDevIndex(i+1),OpenCloseDevIndex(i+2),OpenCloseDevIndex(i+3),OpenCloseDevIndex(i+4),
            ATRIndex(i),ATRIndex(i+1),ATRIndex(i+2),ATRIndex(i+3),ATRIndex(i+4),ADXIndex(i),ADXIndex(i+1),ADXIndex(i+2),ADXIndex(i+3),ADXIndex(i+4),
            MACDIndex(i),MACDIndex(i+1),MACDIndex(i+2),MACDIndex(i+3),MACDIndex(i+4),MADevIndex(i),MADevIndex(i+1),MADevIndex(i+2),MADevIndex(i+3),MADevIndex(i+4),
            MFIIndex(i),MFIIndex(i+1),MFIIndex(i+2),MFIIndex(i+3),MFIIndex(i+4),StochasticIndex(i),StochasticIndex(i+1),StochasticIndex(i+2),StochasticIndex(i+3),StochasticIndex(i+4),
            VolumeIndex(i),VolumeIndex(i+1),VolumeIndex(i+2),VolumeIndex(i+3),VolumeIndex(i+4),AOIndex(i),AOIndex(i+1),AOIndex(i+2),AOIndex(i+3),AOIndex(i+4),
            OBVIndex(i),OBVIndex(i+1),OBVIndex(i+2),OBVIndex(i+3),OBVIndex(i+4),ClassType);
}

void WriteTitleToCSV(int fileHandler) {
  FileWrite(fileHandler,"PairCode","PivotIndex0","PivotIndex1","PivotIndex2","PivotIndex3","PivotIndex4","OpenCloseDevIndex0","OpenCloseDevIndex1","OpenCloseDevIndex2","OpenCloseDevIndex3","OpenCloseDevIndex4",
            "ATRIndex0","ATRIndex1","ATRIndex2","ATRIndex3","ATRIndex4","ADXIndex0","ADXIndex1","ADXIndex2","ADXIndex3","ADXIndex4",
            "MACDIndex0","MACDIndex1","MACDIndex2","MACDIndex3","MACDIndex4","MADevIndex0","MADevIndex1","MADevIndex2","MADevIndex3","MADevIndex4",
            "MFIIndex0","MFIIndex1","MFIIndex2","MFIIndex3","MFIIndex4","StochasticIndex0","StochasticIndex1","StochasticIndex2","StochasticIndex3","StochasticIndex4",
            "VolumeIndex0","VolumeIndex1","VolumeIndex2","VolumeIndex3","VolumeIndex4","AOIndex0","AOIndex1","AOIndex2","AOIndex3","AOIndex4",
            "OBVIndex0","OBVIndex1","OBVIndex2","OBVIndex3","OBVIndex4","ClassType");
}

bool isNotZeroNeuralInput (int i) {
  if ((OpenCloseDevIndex(i) == 0.5 && OpenCloseDevIndex(i+1) == 0.5 && OpenCloseDevIndex(i+2) == 0.5 && OpenCloseDevIndex(i+3) == 0.5 && OpenCloseDevIndex(i+4) == 0.5) || 
      (ATRIndex(i) == 0 && ATRIndex(i+1) == 0 && ATRIndex(i+2) == 0 && ATRIndex(i+3) == 0 && ATRIndex(i+4) == 0) ||
      (ADXIndex(i) == 0 && ADXIndex(i+1) == 0 && ADXIndex(i+2) == 0 && ADXIndex(i+3) == 0 && ADXIndex(i+4) == 0) ||
      (MACDIndex(i) == 0.5 && MACDIndex(i+1) == 0.5 && MACDIndex(i+2) == 0.5 && MACDIndex(i+3) == 0.5 && MACDIndex(i+4) == 0.5) ||
      (MADevIndex(i) == 0.5 && MADevIndex(i+1) == 0.5 && MADevIndex(i+2) == 0.5 && MADevIndex(i+3) == 0.5 && MADevIndex(i+4) == 0.5) ||
      (MFIIndex(i) == 0 && MFIIndex(i+1) == 0 && MFIIndex(i+2) == 0 && MFIIndex(i+3) == 0 && MFIIndex(i+4) == 0) ||
      (StochasticIndex(i) == 0 && StochasticIndex(i+1) == 0 && StochasticIndex(i+2) == 0 && StochasticIndex(i+3) == 0 && StochasticIndex(i+4) == 0) ||
      (VolumeIndex(i) == 0 && VolumeIndex(i+1) == 0 && VolumeIndex(i+2) == 0 && VolumeIndex(i+3) == 0 && VolumeIndex(i+4) == 0) ||
      (AOIndex(i) == 0.5 && AOIndex(i+1) == 0.5 && AOIndex(i+2) == 0.5 && AOIndex(i+3) == 0.5 && AOIndex(i+4) == 0.5) ||
      (OBVIndex(i) == 0.5 && OBVIndex(i+1) == 0.5 && OBVIndex(i+2) == 0.5 && OBVIndex(i+3) == 0.5 && OBVIndex(i+4) == 0.5)) {
        return false;
  } else {return true;}
}

void initNeuronInputArray(int i, double& NeuronInputArray[])
{
  NeuronInputArray[0] = PivotIndex(i);
  NeuronInputArray[1] = PivotIndex(i+1);
  NeuronInputArray[2] = PivotIndex(i+2);
  NeuronInputArray[3] = PivotIndex(i+3);
  NeuronInputArray[4] = PivotIndex(i+4);
  NeuronInputArray[5] = OpenCloseDevIndex(i);
  NeuronInputArray[6] = OpenCloseDevIndex(i+1);
  NeuronInputArray[7] = OpenCloseDevIndex(i+2);
  NeuronInputArray[8] = OpenCloseDevIndex(i+3);
  NeuronInputArray[9] = OpenCloseDevIndex(i+4);
  NeuronInputArray[10] = ATRIndex(i);
  NeuronInputArray[11] = ATRIndex(i+1);
  NeuronInputArray[12] = ATRIndex(i+2);
  NeuronInputArray[13] = ATRIndex(i+3);
  NeuronInputArray[14] = ATRIndex(i+4);
  NeuronInputArray[15] = ADXIndex(i);
  NeuronInputArray[16] = ADXIndex(i+1);
  NeuronInputArray[17] = ADXIndex(i+2);
  NeuronInputArray[18] = ADXIndex(i+3);
  NeuronInputArray[19] = ADXIndex(i+4);
  NeuronInputArray[20] = MACDIndex(i);
  NeuronInputArray[21] = MACDIndex(i+1);
  NeuronInputArray[22] = MACDIndex(i+2);
  NeuronInputArray[23] = MACDIndex(i+3);
  NeuronInputArray[24] = MACDIndex(i+4);
  NeuronInputArray[25] = MADevIndex(i);
  NeuronInputArray[26] = MADevIndex(i+1);
  NeuronInputArray[27] = MADevIndex(i+2);
  NeuronInputArray[28] = MADevIndex(i+3);
  NeuronInputArray[29] = MADevIndex(i+4);
  NeuronInputArray[30] = MFIIndex(i);
  NeuronInputArray[31] = MFIIndex(i+1);
  NeuronInputArray[32] = MFIIndex(i+2);
  NeuronInputArray[33] = MFIIndex(i+3);
  NeuronInputArray[34] = MFIIndex(i+4);
  NeuronInputArray[35] = StochasticIndex(i);
  NeuronInputArray[36] = StochasticIndex(i+1);
  NeuronInputArray[37] = StochasticIndex(i+2);
  NeuronInputArray[38] = StochasticIndex(i+3);
  NeuronInputArray[39] = StochasticIndex(i+4);
  NeuronInputArray[40] = VolumeIndex(i);
  NeuronInputArray[41] = VolumeIndex(i+1);
  NeuronInputArray[42] = VolumeIndex(i+2);
  NeuronInputArray[43] = VolumeIndex(i+3);
  NeuronInputArray[44] = VolumeIndex(i+4);
  NeuronInputArray[45] = AOIndex(i);
  NeuronInputArray[46] = AOIndex(i+1);
  NeuronInputArray[47] = AOIndex(i+2);
  NeuronInputArray[48] = AOIndex(i+3);
  NeuronInputArray[49] = AOIndex(i+4);
  NeuronInputArray[50] = OBVIndex(i);
  NeuronInputArray[51] = OBVIndex(i+1);
  NeuronInputArray[52] = OBVIndex(i+2);
  NeuronInputArray[53] = OBVIndex(i+3);
  NeuronInputArray[54] = OBVIndex(i+4);
}

double normalizeByPoint (double data) {
   return ((1/Point)*data);
}

double MinMaxScaler (double data, double min, double max) {
   return ((data-min)/(max-min));
}

double RangeScaler (double data, double MinRange = 0, double MaxRange = 1) {
   if (data > MaxRange) {return MaxRange;}
   else if (data < MinRange) {return MinRange;}
   else {return data;}
}

double PivotIndex(int i) {
  double ContainerArray[20];

  int timex = iTime(NULL,Period(),i);
  int shft = iBarShift(NULL,TimePeriod,timex,false);

  PPHigh  = NormalizeDouble(iHigh(NULL,TimePeriod,shft+1),8);
  PPLow   = NormalizeDouble(iLow(NULL,TimePeriod,shft+1),8);
  PPOpen  = NormalizeDouble(iOpen(NULL,TimePeriod,shft+1),8);
  PPClose = NormalizeDouble(iClose(NULL,TimePeriod,shft+1),8);  
    
  ContainerArray[0]  = MathAbs(((PPHigh+PPLow+PPClose)/3.0) - NormalizeDouble(Open[i],8));
          
  ContainerArray[1] = MathAbs((2*PP-PPLow) - NormalizeDouble(Open[i],8));
  ContainerArray[2] = MathAbs((PP+(PPHigh - PPLow)) - NormalizeDouble(Open[i],8));
  ContainerArray[3] = MathAbs(((2*PP)+(PPHigh-(2*PPLow))) - NormalizeDouble(Open[i],8));
           
  ContainerArray[4] = MathAbs((2*PP-PPHigh) - NormalizeDouble(Open[i],8));
  ContainerArray[5] = MathAbs((PP-(PPHigh - PPLow)) - NormalizeDouble(Open[i],8));
  ContainerArray[6] = MathAbs(((2*PP)-((2*PPHigh)-PPLow)) - NormalizeDouble(Open[i],8));
            
  ContainerArray[7]=MathAbs((0.5*(S2+S3)) - NormalizeDouble(Open[i],8));
  ContainerArray[8]=MathAbs((0.5*(S1+S2)) - NormalizeDouble(Open[i],8));
  ContainerArray[9]=MathAbs((0.5*(PP+S1)) - NormalizeDouble(Open[i],8));
  ContainerArray[10]=MathAbs((0.5*(PP+R1)) - NormalizeDouble(Open[i],8));
  ContainerArray[11]=MathAbs((0.5*(R1+R2)) - NormalizeDouble(Open[i],8));
  ContainerArray[12]=MathAbs((0.5*(R2+R3)) - NormalizeDouble(Open[i],8));
     
  ContainerArray[13] = MathAbs(((PPLow+(((PPHigh-PPLow)/100)*(100-21.4)))) - NormalizeDouble(Open[i],8));
  ContainerArray[14] = MathAbs(((PPLow+(((PPHigh-PPLow)/100)*(100-23.6)))) - NormalizeDouble(Open[i],8));
  ContainerArray[15] = MathAbs(((PPLow+(((PPHigh-PPLow)/100)*(100-38.2)))) - NormalizeDouble(Open[i],8));
  ContainerArray[16] = MathAbs(((PPLow+(((PPHigh-PPLow)/100)*(100-50)))) - NormalizeDouble(Open[i],8));
  ContainerArray[17] = MathAbs(((PPLow+(((PPHigh-PPLow)/100)*(38.2)))) - NormalizeDouble(Open[i],8));
  ContainerArray[18] = MathAbs(((PPLow+(((PPHigh-PPLow)/100)*(23.6)))) - NormalizeDouble(Open[i],8));
  ContainerArray[19] = MathAbs(((PPLow+(((PPHigh-PPLow)/100)*(21.4)))) - NormalizeDouble(Open[i],8));

  return (1 - (MinMaxScaler(RangeScaler(normalizeByPoint(ContainerArray[ArrayMinimum(ContainerArray)]),0,100),0,100)));
  
  //return RangeScaler(MinMaxScaler((MathSqrt(MathSqrt(normalizeByPoint(ContainerArray[ArrayMinimum(ContainerArray)]))) * 100),0,600));
}

double OpenCloseDevIndex(int i) {
  return RangeScaler(MinMaxScaler(normalizeByPoint(NormalizeDouble(Open[i],8) - NormalizeDouble(Close[i],8)) / MathSqrt(Period()),-100,100));
}

double ATRIndex(int i) {
  double close = Close[i];
  if (close==0) {close=1;}
  return RangeScaler(MinMaxScaler((normalizeByPoint(iATR(NULL,0,14,i)) / normalizeByPoint(close) * 100),0,0.13));
}

double ADXIndex(int i) {
  return RangeScaler(MinMaxScaler(iADX(NULL,0,14,PRICE_HIGH,MODE_MAIN,i),0,100));
}

double MACDIndex(int i) {
  return RangeScaler(MinMaxScaler(normalizeByPoint(iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_MAIN,i)) / MathSqrt(MathSqrt(MathSqrt(Period()))),-200,200));
}

double MADevIndex(int i) {
  return RangeScaler(MinMaxScaler(normalizeByPoint((iMA(NULL, 0, 34, 0, 1, 0, i)) - (iMA(NULL, 0, 55, 0, 1, 0, i))) / MathSqrt(MathSqrt(Period())),-100,100));
}

double MFIIndex(int i) {
  return RangeScaler(MinMaxScaler(iMFI(NULL,0,14,i),0,100));
}

double StochasticIndex(int i) {
  return RangeScaler(MinMaxScaler(iStochastic(NULL,0,5,3,3,MODE_SMA,0,MODE_MAIN,i),0,100));
}

double VolumeIndex (int i) {
  return RangeScaler(MinMaxScaler((NormalizeDouble(iVolume(NULL,0,i),8) / Period()),0,400));
}

double AOIndex (int i) {
  return RangeScaler(MinMaxScaler(normalizeByPoint(iAO(NULL,0,i) - iAO(NULL,0,i+1)) / MathSqrt(MathSqrt(Period())),-30,30));
}

double OBVIndex (int i) {
  return RangeScaler(MinMaxScaler(((NormalizeDouble(iOBV(NULL,0,PRICE_CLOSE,i),8) - NormalizeDouble(iOBV(NULL,0,PRICE_CLOSE,i+1),8)) / Period()),-400,400));
}

bool isUpNeuralNetwork(int i) {
   if (UseNeuralNetwork) {
      if (isNotZeroNeuralInput(i)) {
         initNeuronInputArray(i,neuronInput);
         if (NeuronOutput(neuronInput) == 1) {return true;} else {return false;}
      } else return false;
   } else {
      return true;
   }
}

bool isDownNeuralNetwork(int i) {
   if (UseNeuralNetwork) {
      if (isNotZeroNeuralInput(i)) {
         initNeuronInputArray(i,neuronInput);
         if (NeuronOutput(neuronInput) == 0) {return true;} else {return false;}
      } else return false;
   } else {
      return true;
   }
}
  
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- initialize expiry value once
   expiryCandle=expiryConfig/Period();
   if (expiryCandle<1) expiryCandle = 1;
   tmpExpiry=expiryCandle;
   tickDate=Day();
   MaxWinDelayBuffer=ConsecutiveDelayIndex;
   MaxLoseDelayBuffer=ConsecutiveDelayIndex;
   
   PlotPivots = PivotMode;
   PlotFibots = FibonacciMode;
   PlotMidpoints = MidpointMode;
   
   ArrayResize(winOnExpiry,expiryCandle);
   ArrayResize(loseOnExpiry,expiryCandle);
   ArrayResize(consWinOnExpiry,expiryCandle);
   ArrayResize(consLoseOnExpiry,expiryCandle);
   ArrayResize(bufferMaxWinOnExpiry,expiryCandle);
   ArrayResize(bufferMaxLoseOnExpiry,expiryCandle);
   ArrayResize(MaxWinDelayOnExpiry,expiryCandle);
   ArrayResize(MaxLoseDelayOnExpiry,expiryCandle);
   ArrayResize(MaxWinOnExpiry,expiryCandle);
   ArrayResize(MaxLoseOnExpiry,expiryCandle);
   
   for (int q = 0; q<=ArraySize(MaxWinDelayOnExpiry); q++) {MaxWinDelayOnExpiry[q] = ConsecutiveDelayIndex;}
   for (q = 0; q<=ArraySize(MaxLoseDelayOnExpiry); q++) {MaxLoseDelayOnExpiry[q] = ConsecutiveDelayIndex;}
  
   /*int file_handle=FileOpen("ConsensusData//ConsensusNeuronInput.csv",FILE_READ|FILE_WRITE|FILE_CSV);
   WriteTitleToCSV(file_handle);
   for(int i=0;i<20;i++) {WriteDatasetToCSV(file_handle,i,1);}
   Print("File Print DONE");
   FileClose(file_handle);*/
   
//---- indicators
   SetIndexStyle(0, DRAW_ARROW, EMPTY, 1);
   SetIndexArrow(0, 233);
   SetIndexBuffer(0, CrossUp);
   SetIndexStyle(1, DRAW_ARROW, EMPTY, 1);
   SetIndexArrow(1, 234);
   SetIndexBuffer(1, CrossDown);
   SetIndexStyle(2, DRAW_ARROW, EMPTY, 1);
   SetIndexArrow(2, 252);
   SetIndexBuffer(2, DrawWin);
   SetIndexStyle(3, DRAW_ARROW, EMPTY, 1);
   SetIndexArrow(3, 251);
   SetIndexBuffer(3, DrawLose);
   GlobalVariableSet("AlertTime"+Symbol()+Period(),CurTime());
   GlobalVariableSet("SignalType"+Symbol()+Period(),OP_SELLSTOP);
//   GlobalVariableSet("LastAlert"+Symbol()+Period(),0);

//---- TimeFrame Period Initializaion
   if(TimePeriod==PERIOD_M1||TimePeriod==PERIOD_CURRENT){TimePeriod=PERIOD_M5;period="M5";}
   if(TimePeriod==PERIOD_M5){period="M5";}
   if(TimePeriod==PERIOD_M15){period="M15";}
   if(TimePeriod==PERIOD_M30){period="M30";}
   if(TimePeriod==PERIOD_H1){period="H1";}
   if(TimePeriod==PERIOD_H4){period="H4";}
   if(TimePeriod==PERIOD_D1){period="D1";}
   if(TimePeriod==PERIOD_W1){period="W1";}
   if(TimePeriod==PERIOD_MN1){period="MN1";}   
   
   return(0);
  }
  
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//---- 
   ObjectsDeleteAll();
   GlobalVariableDel("AlertTime"+Symbol()+Period());
   GlobalVariableDel("SignalType"+Symbol()+Period());
//   GlobalVariableDel("LastAlert"+Symbol()+Period());

//----
   return(0);
  }
  
bool PlotTrend(const long              chart_ID=0,
               string                  name="trendline",
               const int               subwindow=0,
               datetime                time1=0,
               double                  price1=0,
               datetime                time2=0,
               double                  price2=0,             
               const color             clr=clrBlack,
               const ENUM_LINE_STYLE   style=STYLE_SOLID,
               const int               width=2,
               const bool              back=true,
               const bool              selection=false,
               const bool              ray=false,
               const bool              hidden=true)
{
   ResetLastError();
   if(!ObjectCreate(chart_ID,name,OBJ_TREND,subwindow,time1,price1,time2,price2))
   {
      //Print(__FUNCTION__,": failed to create arrow = ",GetLastError());
      return(false);
   }
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_RAY,ray);
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
   return(true);
}

bool PlotRectangle(  const long        chart_ID=0,
                     string            name="rectangle", 
                     const int         subwindow=0,
                     datetime          time1=0,
                     double            price1=1,
                     datetime          time2=0, 
                     double            price2=0, 
                     const color       clr=clrGray,
                     const bool        back=true,
                     const bool        selection=false,
                     const bool        hidden=true)
{
   if(!ObjectCreate(chart_ID,name,OBJ_RECTANGLE,subwindow,time1,price1,time2,price2))
   {
      //Print(__FUNCTION__,": failed to create arrow = ",GetLastError());
      return(false);
   }
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
   return(true);
}

bool PlotText(       const long        chart_ID=0,
                     string            name="text", 
                     const int         subwindow=0,
                     datetime          time1=0, 
                     double            price1=0, 
                     const string      text="text",
                     const string      font="Arial",
                     const int         font_size=10,
                     const color       clr=clrGray,
                     const ENUM_ANCHOR_POINT anchor = ANCHOR_RIGHT_UPPER,
                     const bool        back=true,
                     const bool        selection=false,
                     const bool        hidden=true)
{
   ResetLastError();
   if(!ObjectCreate(chart_ID,name,OBJ_TEXT,subwindow,time1,price1))
   {
      //Print(__FUNCTION__,": failed to create arrow = ",GetLastError());
      return(false);
   }
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
   return(true);
} 
       
void LevelsDraw( int shft, datetime tmestrt, datetime tmend, string name)
{
   PPHigh  = iHigh(NULL,TimePeriod,shft);
   PPLow   = iLow(NULL,TimePeriod,shft);
   PPOpen  = iOpen(NULL,TimePeriod,shft);
   PPClose = iClose(NULL,TimePeriod,shft);  
     
   PP  = (PPHigh+PPLow+PPClose)/3.0;
           
   R1 = 2*PP-PPLow;
   R2 = PP+(PPHigh - PPLow);
   R3 = (2*PP)+(PPHigh-(2*PPLow));
            
   S1 = 2*PP-PPHigh;
   S2 = PP-(PPHigh - PPLow);
   S3 = (2*PP)-((2*PPHigh)-PPLow);
             
   M0=0.5*(S2+S3);
   M1=0.5*(S1+S2);
   M2=0.5*(PP+S1);
   M3=0.5*(PP+R1);
   M4=0.5*(R1+R2);
   M5=0.5*(R2+R3);
      
   f214 = (PPLow+(((PPHigh-PPLow)/100)*(100-21.4)));
   f236 = (PPLow+(((PPHigh-PPLow)/100)*(100-23.6)));
   f382 = (PPLow+(((PPHigh-PPLow)/100)*(100-38.2)));
   f50  = (PPLow+(((PPHigh-PPLow)/100)*(100-50)));
   f618 = (PPLow+(((PPHigh-PPLow)/100)*(38.2)));
   f764 = (PPLow+(((PPHigh-PPLow)/100)*(23.6)));
   f786 = (PPLow+(((PPHigh-PPLow)/100)*(21.4)));

   if(PlotPivots){                                 
      PlotTrend(0,"R3"+name,0,tmestrt,R3,tmend,R3,ColorRes,StylePivots,WidthPivots);     
      PlotTrend(0,"R2"+name,0,tmestrt,R2,tmend,R2,ColorRes,StylePivots,WidthPivots);     
      PlotTrend(0,"R1"+name,0,tmestrt,R1,tmend,R1,ColorRes,StylePivots,WidthPivots);     
      PlotTrend(0,"PP"+name,0,tmestrt,PP,tmend,PP,ColorPP,StylePivots,WidthPivots);     
      PlotTrend(0,"S1"+name,0,tmestrt,S1,tmend,S1,ColorSup,StylePivots,WidthPivots);     
      PlotTrend(0,"S2"+name,0,tmestrt,S2,tmend,S2,ColorSup,StylePivots,WidthPivots);     
      PlotTrend(0,"S3"+name,0,tmestrt,S3,tmend,S3,ColorSup,StylePivots,WidthPivots);
      if(PlotPivotLabels){
         PlotText(0,"R3L"+name,0,tmend,R3,"R3","Arial",8,ColorRes,ANCHOR_RIGHT_UPPER);
         PlotText(0,"R2L"+name,0,tmend,R2,"R2","Arial",8,ColorRes,ANCHOR_RIGHT_UPPER);
         PlotText(0,"R1L"+name,0,tmend,R1,"R1","Arial",8,ColorRes,ANCHOR_RIGHT_UPPER);
         PlotText(0,"PPL"+name,0,tmend,PP,"PP","Arial",8,ColorPP,ANCHOR_RIGHT_UPPER);
         PlotText(0,"S1L"+name,0,tmend,S1,"S1","Arial",8,ColorSup,ANCHOR_RIGHT_UPPER);
         PlotText(0,"S2L"+name,0,tmend,S2,"S2","Arial",8,ColorSup,ANCHOR_RIGHT_UPPER);
         PlotText(0,"S3L"+name,0,tmend,S3,"S3","Arial",8,ColorSup,ANCHOR_RIGHT_UPPER);}    
      if(PlotPivotPrices){
         PlotText(0,"R3P"+name,0,tmestrt,R3,DoubleToString(R3,4),"Arial",8,ColorRes,ANCHOR_LEFT_UPPER);
         PlotText(0,"R2P"+name,0,tmestrt,R2,DoubleToString(R2,4),"Arial",8,ColorRes,ANCHOR_LEFT_UPPER);
         PlotText(0,"R1P"+name,0,tmestrt,R1,DoubleToString(R1,4),"Arial",8,ColorRes,ANCHOR_LEFT_UPPER);
         PlotText(0,"PPP"+name,0,tmestrt,PP,DoubleToString(PP,4),"Arial",8,ColorPP,ANCHOR_LEFT_UPPER);
         PlotText(0,"S1P"+name,0,tmestrt,S1,DoubleToString(S1,4),"Arial",8,ColorSup,ANCHOR_LEFT_UPPER);
         PlotText(0,"S2P"+name,0,tmestrt,S2,DoubleToString(S2,4),"Arial",8,ColorSup,ANCHOR_LEFT_UPPER);
         PlotText(0,"S3P"+name,0,tmestrt,S3,DoubleToString(S3,4),"Arial",8,ColorSup,ANCHOR_LEFT_UPPER);}}    

   if(PlotMidpoints){
      PlotTrend(0,"M0"+name,0,tmestrt,M0,tmend,M0,ColorM02,StyleMidpoints,WidthMidpoints);     
      PlotTrend(0,"M1"+name,0,tmestrt,M1,tmend,M1,ColorM02,StyleMidpoints,WidthMidpoints);     
      PlotTrend(0,"M2"+name,0,tmestrt,M2,tmend,M2,ColorM02,StyleMidpoints,WidthMidpoints);     
      PlotTrend(0,"M3"+name,0,tmestrt,M3,tmend,M3,ColorM35,StyleMidpoints,WidthMidpoints);     
      PlotTrend(0,"M4"+name,0,tmestrt,M4,tmend,M4,ColorM35,StyleMidpoints,WidthMidpoints);     
      PlotTrend(0,"M5"+name,0,tmestrt,M5,tmend,M5,ColorM35,StyleMidpoints,WidthMidpoints);
      if(PlotPivotLabels){
         PlotText(0,"M0L"+name,0,tmend,M0,"M0","Arial",8,ColorSup,ANCHOR_RIGHT_UPPER);
         PlotText(0,"M1L"+name,0,tmend,M1,"M1","Arial",8,ColorSup,ANCHOR_RIGHT_UPPER);
         PlotText(0,"M2L"+name,0,tmend,M2,"M2","Arial",8,ColorSup,ANCHOR_RIGHT_UPPER);
         PlotText(0,"M3L"+name,0,tmend,M3,"M3","Arial",8,ColorRes,ANCHOR_RIGHT_UPPER);
         PlotText(0,"M4L"+name,0,tmend,M4,"M4","Arial",8,ColorRes,ANCHOR_RIGHT_UPPER);
         PlotText(0,"M5L"+name,0,tmend,M5,"M5","Arial",8,ColorRes,ANCHOR_RIGHT_UPPER);}
      if(PlotPivotPrices){
         PlotText(0,"M0P"+name,0,tmestrt,M0,DoubleToString(M0,4),"Arial",8,ColorSup,ANCHOR_LEFT_UPPER);
         PlotText(0,"M1P"+name,0,tmestrt,M1,DoubleToString(M1,4),"Arial",8,ColorSup,ANCHOR_LEFT_UPPER);
         PlotText(0,"M2P"+name,0,tmestrt,M2,DoubleToString(M2,4),"Arial",8,ColorSup,ANCHOR_LEFT_UPPER);
         PlotText(0,"M3P"+name,0,tmestrt,M3,DoubleToString(M3,4),"Arial",8,ColorRes,ANCHOR_LEFT_UPPER);
         PlotText(0,"M4P"+name,0,tmestrt,M4,DoubleToString(M4,4),"Arial",8,ColorRes,ANCHOR_LEFT_UPPER);
         PlotText(0,"M5P"+name,0,tmestrt,M5,DoubleToString(M5,4),"Arial",8,ColorRes,ANCHOR_LEFT_UPPER);}}   
 
   if(PlotZones){
      PlotRectangle(0,"BZ"+name,0,tmestrt,M1,tmend,S2,ColorBuyZone);    
      PlotRectangle(0,"SZ"+name,0,tmestrt,M4,tmend,R2,ColorSellZone);}
   
   if(PlotBorders){  
      PlotTrend(0,"BDL"+name,0,tmestrt,R2,tmestrt,S2,ColorBorder,StyleBorder,WidthBorder);     
      PlotTrend(0,"BDR"+name,0,tmend,R2,tmend,S2,ColorBorder,StyleBorder,WidthBorder);}
              
   if(PlotFibots){
      PlotTrend(0,"f214a"+name,0,tmestrt,f214,tmend,f214,ColorFibots,StyleFibots1,WidthFibots1);
      PlotTrend(0,"f382a"+name,0,tmestrt,f382,tmend,f382,ColorFibots,StyleFibots1,WidthFibots1);
      PlotTrend(0,"f50a"+name,0,tmestrt,f50,tmend,f50,ColorFibots,StyleFibots1,WidthFibots1);
      PlotTrend(0,"f618a"+name,0,tmestrt,f618,tmend,f618,ColorFibots,StyleFibots1,WidthFibots1);
      PlotTrend(0,"f786a"+name,0,tmestrt,f786,tmend,f786,ColorFibots,StyleFibots1,WidthFibots1);
      PlotTrend(0,"f214b"+name,0,tmestrt+TimePeriod*10,f214,tmend,f214,ColorFibots,StyleFibots2,WidthFibots2);
      PlotTrend(0,"f382b"+name,0,tmestrt+TimePeriod*10,f382,tmend,f382,ColorFibots,StyleFibots2,WidthFibots2);
      PlotTrend(0,"f50b"+name,0,tmestrt+TimePeriod*10,f50,tmend,f50,ColorFibots,StyleFibots2,WidthFibots2);
      PlotTrend(0,"f618b"+name,0,tmestrt+TimePeriod*10,f618,tmend,f618,ColorFibots,StyleFibots2,WidthFibots2);
      PlotTrend(0,"f786b"+name,0,tmestrt+TimePeriod*10,f786,tmend,f786,ColorFibots,StyleFibots2,WidthFibots2);
      if(PlotFibotLabels){
         PlotText(0,"f214l"+name,0,tmend,f214,"21.4%","Arial",8,ColorFibots,ANCHOR_RIGHT_UPPER);         
         PlotText(0,"f382l"+name,0,tmend,f382,"38.2%","Arial",8,ColorFibots,ANCHOR_RIGHT_UPPER);         
         PlotText(0,"f50l"+name,0,tmend,f50,"50%","Arial",8,ColorFibots,ANCHOR_RIGHT_UPPER);         
         PlotText(0,"f618l"+name,0,tmend,f618,"61.8%","Arial",8,ColorFibots,ANCHOR_RIGHT_UPPER);         
         PlotText(0,"f786l"+name,0,tmend,f786,"78.6%","Arial",8,ColorFibots,ANCHOR_RIGHT_UPPER);}
      if(PlotFibotPrices){
         PlotText(0,"f214p"+name,0,tmestrt,f214,DoubleToString(f214,4),"Arial",8,ColorFibots,ANCHOR_LEFT_UPPER);         
         PlotText(0,"f382p"+name,0,tmestrt,f382,DoubleToString(f382,4),"Arial",8,ColorFibots,ANCHOR_LEFT_UPPER);         
         PlotText(0,"f50p"+name,0,tmestrt,f50,DoubleToString(f50,4),"Arial",8,ColorFibots,ANCHOR_LEFT_UPPER);         
         PlotText(0,"f618p"+name,0,tmestrt,f618,DoubleToString(f618,4),"Arial",8,ColorFibots,ANCHOR_LEFT_UPPER);         
         PlotText(0,"f786p"+name,0,tmestrt,f786,DoubleToString(f786,4),"Arial",8,ColorFibots,ANCHOR_LEFT_UPPER);}}    
}

bool isOnPivotLevel( int i )
{
   if (UsePivotFilter) {

      int timex = iTime(NULL,Period(),i);
      int shft = iBarShift(NULL,TimePeriod,timex,false);

      PPHigh  = iHigh(NULL,TimePeriod,shft+1);
      PPLow   = iLow(NULL,TimePeriod,shft+1);
      PPOpen  = iOpen(NULL,TimePeriod,shft+1);
      PPClose = iClose(NULL,TimePeriod,shft+1);  
        
      PP  = (PPHigh+PPLow+PPClose)/3.0;
              
      R1 = 2*PP-PPLow;
      R2 = PP+(PPHigh - PPLow);
      R3 = (2*PP)+(PPHigh-(2*PPLow));
               
      S1 = 2*PP-PPHigh;
      S2 = PP-(PPHigh - PPLow);
      S3 = (2*PP)-((2*PPHigh)-PPLow);
                
      M0=0.5*(S2+S3);
      M1=0.5*(S1+S2);
      M2=0.5*(PP+S1);
      M3=0.5*(PP+R1);
      M4=0.5*(R1+R2);
      M5=0.5*(R2+R3);
         
      f214 = (PPLow+(((PPHigh-PPLow)/100)*(100-21.4)));
      f236 = (PPLow+(((PPHigh-PPLow)/100)*(100-23.6)));
      f382 = (PPLow+(((PPHigh-PPLow)/100)*(100-38.2)));
      f50  = (PPLow+(((PPHigh-PPLow)/100)*(100-50)));
      f618 = (PPLow+(((PPHigh-PPLow)/100)*(38.2)));
      f764 = (PPLow+(((PPHigh-PPLow)/100)*(23.6)));
      f786 = (PPLow+(((PPHigh-PPLow)/100)*(21.4)));

      PivotLevelArray[0,0] = PP+(PivotLevelRange*Point);      
      PivotLevelArray[0,1] = PP-(PivotLevelRange*Point);

      PivotLevelArray[1,0] = R1+(PivotLevelRange*Point);
      PivotLevelArray[1,1] = R1-(PivotLevelRange*Point);

      PivotLevelArray[2,0] = R2+(PivotLevelRange*Point);
      PivotLevelArray[2,1] = R2-(PivotLevelRange*Point);

      PivotLevelArray[3,0] = R3+(PivotLevelRange*Point);
      PivotLevelArray[3,1] = R3-(PivotLevelRange*Point);

      PivotLevelArray[4,0] = S1+(PivotLevelRange*Point);
      PivotLevelArray[4,1] = S1-(PivotLevelRange*Point);

      PivotLevelArray[5,0] = S2+(PivotLevelRange*Point);
      PivotLevelArray[5,1] = S2-(PivotLevelRange*Point);

      PivotLevelArray[6,0] = S3+(PivotLevelRange*Point);
      PivotLevelArray[6,1] = S3-(PivotLevelRange*Point);

      PivotLevelArray[7,0] = M0+(PivotLevelRange*Point);
      PivotLevelArray[7,1] = M0-(PivotLevelRange*Point);

      PivotLevelArray[8,0] = M1+(PivotLevelRange*Point);
      PivotLevelArray[8,1] = M1-(PivotLevelRange*Point);

      PivotLevelArray[9,0] = M2+(PivotLevelRange*Point);
      PivotLevelArray[9,1] = M2-(PivotLevelRange*Point);

      PivotLevelArray[10,0] = M3+(PivotLevelRange*Point);
      PivotLevelArray[10,1] = M3-(PivotLevelRange*Point);

      PivotLevelArray[11,0] = M4+(PivotLevelRange*Point);
      PivotLevelArray[11,1] = M4-(PivotLevelRange*Point);

      PivotLevelArray[12,0] = M5+(PivotLevelRange*Point);
      PivotLevelArray[12,1] = M5-(PivotLevelRange*Point);

      PivotLevelArray[13,0] = f214+(PivotLevelRange*Point);
      PivotLevelArray[13,1] = f214-(PivotLevelRange*Point);

      PivotLevelArray[14,0] = f236+(PivotLevelRange*Point);
      PivotLevelArray[14,1] = f236-(PivotLevelRange*Point);

      PivotLevelArray[15,0] = f382+(PivotLevelRange*Point);
      PivotLevelArray[15,1] = f382-(PivotLevelRange*Point);

      PivotLevelArray[16,0] = f50+(PivotLevelRange*Point);
      PivotLevelArray[16,1] = f50-(PivotLevelRange*Point);

      PivotLevelArray[17,0] = f618+(PivotLevelRange*Point);
      PivotLevelArray[17,1] = f618-(PivotLevelRange*Point);

      PivotLevelArray[18,0] = f764+(PivotLevelRange*Point);
      PivotLevelArray[18,1] = f764-(PivotLevelRange*Point);

      PivotLevelArray[19,0] = f786+(PivotLevelRange*Point);
      PivotLevelArray[19,1] = f786-(PivotLevelRange*Point);

      if (PivotLevelArray[0][0]==0) {return false;}
      else {
         if (PivotMode) {
            if (Open[i]<PivotLevelArray[0][0] && Open[i]>PivotLevelArray[0][1]) {return true;}
            else if (Open[i]<PivotLevelArray[1][0] && Open[i]>PivotLevelArray[1][1]) {return true;}
            else if (Open[i]<PivotLevelArray[2][0] && Open[i]>PivotLevelArray[2][1]) {return true;}
            else if (Open[i]<PivotLevelArray[3][0] && Open[i]>PivotLevelArray[3][1]) {return true;}
            else if (Open[i]<PivotLevelArray[4][0] && Open[i]>PivotLevelArray[4][1]) {return true;}
            else if (Open[i]<PivotLevelArray[5][0] && Open[i]>PivotLevelArray[5][1]) {return true;}
            else if (Open[i]<PivotLevelArray[6][0] && Open[i]>PivotLevelArray[6][1]) {return true;}
         }
         
         if (MidpointMode) {
            if (Open[i]<PivotLevelArray[7][0] && Open[i]>PivotLevelArray[7][1]) {return true;}
            else if (Open[i]<PivotLevelArray[8][0] && Open[i]>PivotLevelArray[8][1]) {return true;}
            else if (Open[i]<PivotLevelArray[9][0] && Open[i]>PivotLevelArray[9][1]) {return true;}
            else if (Open[i]<PivotLevelArray[10][0] && Open[i]>PivotLevelArray[10][1]) {return true;}
            else if (Open[i]<PivotLevelArray[11][0] && Open[i]>PivotLevelArray[11][1]) {return true;}
            else if (Open[i]<PivotLevelArray[12][0] && Open[i]>PivotLevelArray[12][1]) {return true;}
         }
         
         if (FibonacciMode) {
            if (Open[i]<PivotLevelArray[13][0] && Open[i]>PivotLevelArray[13][1]) {return true;}
            else if (Open[i]<PivotLevelArray[14][0] && Open[i]>PivotLevelArray[14][1]) {return true;}
            else if (Open[i]<PivotLevelArray[15][0] && Open[i]>PivotLevelArray[15][1]) {return true;}
            else if (Open[i]<PivotLevelArray[16][0] && Open[i]>PivotLevelArray[16][1]) {return true;}
            else if (Open[i]<PivotLevelArray[17][0] && Open[i]>PivotLevelArray[17][1]) {return true;}
            else if (Open[i]<PivotLevelArray[18][0] && Open[i]>PivotLevelArray[18][1]) {return true;}
            else if (Open[i]<PivotLevelArray[19][0] && Open[i]>PivotLevelArray[19][1]) {return true;}
         }
     
         return false;
         
      }

   } else return true;
}

bool isUpMACD (int i) {
   if (UseMACD) {
      if (iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_MAIN,i) > 0 ) return true; else return false;
   } else return true;
}

bool isDownMACD (int i) {
   if (UseMACD) {
      if (iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_MAIN,i) < 0 ) return true; else return false;
   } else return true;
}

bool isUpHeikinAshi (int i) {
   if (UseHeikinAshi) {
      double open = iCustom(Symbol(), 0, "Heiken Ashi", 2, i);
      double close = iCustom(Symbol(), 0, "Heiken Ashi", 3, i);
      if(open < close) { return true; } else { return false; }
   } else return true;
}

bool isDownHeikinAshi (int i) {
   if (UseHeikinAshi) {
      double open = iCustom(Symbol(), 0, "Heiken Ashi", 2, i);
      double close = iCustom(Symbol(), 0, "Heiken Ashi", 3, i);
      if(open > close) { return true; } else { return false; }
   } else return true;
}

bool isOversoldBB (int i){
   if (UseBBDefault) {
      if ((Close[i]-iBands(NULL,0,BBPeriod,StdDeviation,0,0,MODE_HIGH,i))==0) return false;
      if (iBands(NULL,0,BBPeriod,StdDeviation,0,0,MODE_LOW,i)==0) return false;
      if (iBands(NULL,0,BBPeriod,StdDeviation,0,0,MODE_HIGH,i)==0) return false;
      double BBValue;
      BBValue=(Close[i]-iBands(NULL,0,BBPeriod,StdDeviation,0,0,MODE_HIGH,i))/(iBands(NULL,0,BBPeriod,StdDeviation,0,0,MODE_LOW,i)-iBands(NULL,0,BBPeriod,StdDeviation,0,0,MODE_HIGH,i));
      if (BBTrendMode){if (BBValue>0.5) {return true;} else {return false;}}
      else {if (BBValue<OversoldBBLevel) {return true;} else {return false;}}
   } else {return true;}
}

bool isOverboughtBB (int i){
   if (UseBBDefault) {
      if ((Close[i]-iBands(NULL,0,BBPeriod,StdDeviation,0,0,MODE_HIGH,i))==0) return false;
      if (iBands(NULL,0,BBPeriod,StdDeviation,0,0,MODE_LOW,i)==0) return false;
      if (iBands(NULL,0,BBPeriod,StdDeviation,0,0,MODE_HIGH,i)==0) return false;
      double BBValue;
      BBValue=(Close[i]-iBands(NULL,0,BBPeriod,StdDeviation,0,0,MODE_HIGH,i))/(iBands(NULL,0,BBPeriod,StdDeviation,0,0,MODE_LOW,i)-iBands(NULL,0,BBPeriod,StdDeviation,0,0,MODE_HIGH,i));
      if (BBTrendMode){if (BBValue<0.5) {return true;} else {return false;}}
      else {if (BBValue>OverboughtBBLevel) {return true;} else {return false;}}
   } else {return true;}
}

double AveRange4(int pos)
{
   double sum;
   double rangeSerie[4];
   
   int i=0;
   int ind=1;
   int startYear=1995;
   int den;
   
   if(pos<=0)den=1;
   else den = pos;
   if (TimeYear(Time[den-1])>=startYear)
   {
      while (i<4)
      {
         //datetime pok=Time[pos+ind];
         if(TimeDayOfWeek(Time[pos+ind])!=0)
         {
            sum+=High[pos+ind]-Low[pos+ind];//make summation
            i++;
         }
         ind++;   
         //i++;
      }
      //Comment(sum/4.0);
      return (sum/4.0);//make average, don't count min and max, this is why I divide by 4 and not by 6
   } 
      return (50*Point);
   
}

bool IsBuyPinbar(double& DayRange, int pos)
{
   if (UseCandleFilter && UsePinbar) {
   
   //start of declarations
   double actOp,actCl,actHi,actLo,preHi,preLo,preCl,preOp,actRange,preRange,actHigherPart,actHigherPart1;
   actOp=Open[pos+1];  //O
   actCl=Close[pos+1]; //C
   actHi=High[pos+1];  //H
   actLo=Low[pos+1];   //L
   preOp=Open[pos+2];   //O1
   preCl=Close[pos+2];  //C1
   preHi=High[pos+2];   ////H1
   preLo=Low[pos+2];    //L1
   //SetProxy(preHi,preLo,preOp,preCl);//Check proxy
   actRange=actHi-actLo; //CL
   preRange=preHi-preLo; //CL1
   actHigherPart=actHi-actRange*0.4;//helping variable to not have too much counting in IF part
   actHigherPart1=actHi-actRange*0.4;//helping variable to not have too much counting in IF part
   //end of declaratins
   //start function body
   dayRange=AveRange4(pos);
   if((actCl>actHigherPart1&&actOp>actHigherPart)&&  //Close&Open of PB is in higher 1/3 of PB
      (actRange>dayRange*0.5)&& //PB is not too small
      //(actHi<(preHi-preRange*0.3))&& //High of PB is NOT higher than 1/2 of previous Bar
      (actLo+actRange*0.25<preLo)) //Nose of the PB is at least 1/3 lower than previous bar
   {
    
      if(Low[ArrayMinimum(Low,3,pos+3)]>Low[pos+1])
         return (true);
   }
   return(false);
   
   } else return true;
   
}

bool IsSellPinbar(double& DayRange, int pos)
{
   if (UseCandleFilter && UsePinbar) {
   
   //start of declarations
   double actOp,actCl,actHi,actLo,preHi,preLo,preCl,preOp,actRange,preRange,actLowerPart, actLowerPart1;
   actOp=Open[pos+1];
   actCl=Close[pos+1];
   actHi=High[pos+1];
   actLo=Low[pos+1];
   preOp=Open[pos+2];
   preCl=Close[pos+2];
   preHi=High[pos+2];
   preLo=Low[pos+2];
   //SetProxy(preHi,preLo,preOp,preCl);//Check proxy
   actRange=actHi-actLo;
   preRange=preHi-preLo;
   actLowerPart=actLo+actRange*0.4;//helping variable to not have too much counting in IF part
   actLowerPart1=actLo+actRange*0.4;//helping variable to not have too much counting in IF part
   //end of declaratins
   
   //start function body

   dayRange=AveRange4(pos);
   if((actCl<actLowerPart1&&actOp<actLowerPart)&&  //Close&Open of PB is in higher 1/3 of PB
      (actRange>dayRange*0.5)&& //PB is not too small
      //(actLo>(preLo+preRange/3.0))&& //Low of PB is NOT lower than 1/2 of previous Bar
      (actHi-actRange*0.25>preHi)) //Nose of the PB is at least 1/3 lower than previous bar
      
   {
      if(High[ArrayMaximum(High,3,pos+3)]<High[pos+1])
         return (true);
   }
   return (false);
   
   } else return true;
}

bool isBulishCandle(int shift, int Star_Body_Length = 5){

   if (UseCandleFilter) {
   
   if (UsePinbar) {return true;}

   double Range, AvgRange;
   int counter;

   int shift1;
   int shift2;
   int shift3;
   int shift4;

   int Doji_Star_Ratio;
   double Piercing_Line_Ratio;
   int Piercing_Candle_Length;
   int Engulfing_Length;
   double Doji_MinLength = 0;
   double Star_MinLength = 0;

   double O, O1, O2, C, C1, C2, C3, L, L1, L2, L3, H, H1, H2, H3;
   double CL, CL1, CL2, BL, BLa, BL90, UW, LW, BodyHigh, BodyLow;
   BodyHigh = 0;
   BodyLow = 0;
   
   double Candle_WickBody_Percent = 0.9;
   int CandleLength = 12;  

   switch (Period()) {
      case 1:
         Doji_Star_Ratio = 0;
         Piercing_Line_Ratio = 0.5;
         Piercing_Candle_Length = 10;
         Engulfing_Length = 10;
         break;
      case 5:
         Doji_Star_Ratio = 0;
         Piercing_Line_Ratio = 0.5;
         Piercing_Candle_Length = 10;
         Engulfing_Length = 10;
         break;
      case 15:
         Doji_Star_Ratio = 0;
         Piercing_Line_Ratio = 0.5;
         Piercing_Candle_Length = 10;
         Engulfing_Length = 0;
         break;
      case 30:
         Doji_Star_Ratio = 0;
         Piercing_Line_Ratio = 0.5;
         Piercing_Candle_Length = 10;
         Engulfing_Length = 15;
         break;      
      case 60:
         Doji_Star_Ratio = 0;
         Piercing_Line_Ratio = 0.5;
         Piercing_Candle_Length = 10;
         Engulfing_Length = 25;
         break;
      case 240:
         Doji_Star_Ratio = 0;
         Piercing_Line_Ratio = 0.5;
         Piercing_Candle_Length = 10;
         Engulfing_Length = 20;
         break;
      case 1440:
         Doji_Star_Ratio = 0;
         Piercing_Line_Ratio = 0.5;
         Piercing_Candle_Length = 10;
         Engulfing_Length = 30;
         break;
      case 10080:
         Doji_Star_Ratio = 0;
         Piercing_Line_Ratio = 0.5;
         Piercing_Candle_Length = 10;
         Engulfing_Length = 40;
         break;
      case 43200:
         Doji_Star_Ratio = 0;
         Piercing_Line_Ratio = 0.5;
         Piercing_Candle_Length = 10;
         Engulfing_Length = 50;
         break;
   }
         
      counter=shift;
      Range=0;
      AvgRange=0;
      for (counter=shift ;counter<=shift+9;counter++) {
         AvgRange=AvgRange+MathAbs(High[counter]-Low[counter]);
      }
      Range=AvgRange/10;
      shift1 = shift + 1;
      shift2 = shift + 2;
      shift3 = shift + 3;
      shift4 = shift + 4;
      
      
      O = Open[shift1];
      O1 = Open[shift2];
      O2 = Open[shift3];
      H = High[shift1];
      H1 = High[shift2];
      H2 = High[shift3];
      H3 = High[shift4];
      L = Low[shift1];
      L1 = Low[shift2];
      L2 = Low[shift3];
      L3 = Low[shift4];
      C = Close[shift1];
      C1 = Close[shift2];
      C2 = Close[shift3];
      C3 = Close[shift4];
      if (O>C) {
         BodyHigh = O;
         BodyLow = C;  }
      else {
         BodyHigh = C;
         BodyLow = O; }
      CL = High[shift1]-Low[shift1];
      CL1 = High[shift2]-Low[shift2];
      CL2 = High[shift3]-Low[shift3];
      BL = Open[shift1]-Close[shift1];
      UW = High[shift1]-BodyHigh;
      LW = BodyLow-Low[shift1];
      BLa = MathAbs(BL);
      BL90 = BLa*Candle_WickBody_Percent;
   
 // Bullish Patterns
   
      // Check for Bullish Hammer   
      if ((L<=L1)&&(L<L2)&&(L<L3))  {
      if (UseHammer)  {
         if (((LW/2)>UW)&&(LW>BL90)&&(CL>=(CandleLength*Point))&&(O!=C)&&((LW/3)<=UW)&&((LW/4)<=UW)/*&&(H<H1)&&(H<H2)*/)  { return true;}
         else if (((LW/3)>UW)&&(LW>BL90)&&(CL>=(CandleLength*Point))&&(O!=C)&&((LW/4)<=UW)/*&&(H<H1)&&(H<H2)*/)  {return true;}
         else if (((LW/4)>UW)&&(LW>BL90)&&(CL>=(CandleLength*Point))&&(O!=C)/*&&(H<H1)&&(H<H2)*/)  {return true;}
         else return false; 
      } else return false;   
      }  

     // Check for Morning Star
      else if (/*(H1<(BL/2))&&*/(BLa<(Star_Body_Length*Point))&&(!O==C)&&((O2>C2)&&((O2-C2)/(0.001+H2-L2)>Doji_Star_Ratio))/*&&(C2>O1)*/&&(O1>C1)/*&&((H1-L1)>(3*(C1-O1)))*/&&(C>O)&&(CL>=(Star_MinLength*Point))) {
         if (UseStar) {   
            return true;
         } else return false;
      } 
      
      
      // Check for Morning Doji Star
      else if (/*(H1<(BL/2))&&*/(O==C)&&((O2>C2)&&((O2-C2)/(0.001+H2-L2)>Doji_Star_Ratio))/*&&(C2>O1)*/&&(O1>C1)/*&&((H1-L1)>(3*(C1-O1)))*/&&(CL>=(Doji_MinLength*Point))) {
         if (UseDoji) {   
            return true;
         } else return false;
      }
      
      // Check for Piercing Line pattern
      else if ((C1<O1)&&(((O1+C1)/2)<C)&&(O<C)&&(O<C1)&&(C<O1)&&((C-O)/(0.001+(H-L))>0.6)) {
         if (UsePiercingLine) {   
            return true;
         } else return false;
      }  
      
      // Check for Bullish Harami pattern
      else if ((O1>C1)&&(C>O)&&(C<=O1)&&(C1<=O)&&((C-O)<(O1-C1))) {
         if (UseHarami) {   
            return true;
         } else return false;
      } 
      
      // Check for Three Outside Up pattern
      else if ((O2>C2)&&(C1>O1)&&(C1>=O2)&&(C2>=O1)&&((C1-O1)>(O2-C2))&&(C>O)&&(C>C1)) {
         if (Use3Outside) {   
            return true;
         } else return false;
      }  
      
      // Check for Three Inside Up pattern
      else if ((O2>C2)&&(C1>O1)&&(C1<=O2)&&(C2<=O1)&&((C1-O1)<(O2-C2))&&(C>O)&&(C>C1)&&(O>O1)) {
         if (Use3Outside) {   
            return true;
         } else return false;
      } 

      // Check for Bullish Engulfing pattern
      else if ((O1>C1)&&(C>O)&&(C>=O1)&&(C1>=O)&&((C-O)>(O1-C1))) {
         if (UseEngulfing) {   
            return true;
         } else return false;
      } else return false;
      
   } else return true;
}

bool isBearsihCandle(int shift, int Star_Body_Length = 5) {

   if (UseCandleFilter) {
   
   if (UsePinbar) {return true;}
   
   double Range, AvgRange;
   int counter;

   int shift1;
   int shift2;
   int shift3;
   int shift4;

   int Doji_Star_Ratio;
   double Piercing_Line_Ratio;
   int Piercing_Candle_Length;
   int Engulfing_Length;
   double Doji_MinLength = 0;
   double Star_MinLength = 0;

   double O, O1, O2, C, C1, C2, C3, L, L1, L2, L3, H, H1, H2, H3;
   double CL, CL1, CL2, BL, BLa, BL90, UW, LW, BodyHigh, BodyLow;
   BodyHigh = 0;
   BodyLow = 0;
   
   double Candle_WickBody_Percent = 0.9;
   int CandleLength = 12;  

   switch (Period()) {
      case 1:
         Doji_Star_Ratio = 0;
         Piercing_Line_Ratio = 0.5;
         Piercing_Candle_Length = 10;
         Engulfing_Length = 10;
         break;
      case 5:
         Doji_Star_Ratio = 0;
         Piercing_Line_Ratio = 0.5;
         Piercing_Candle_Length = 10;
         Engulfing_Length = 10;
         break;
      case 15:
         Doji_Star_Ratio = 0;
         Piercing_Line_Ratio = 0.5;
         Piercing_Candle_Length = 10;
         Engulfing_Length = 0;
         break;
      case 30:
         Doji_Star_Ratio = 0;
         Piercing_Line_Ratio = 0.5;
         Piercing_Candle_Length = 10;
         Engulfing_Length = 15;
         break;      
      case 60:
         Doji_Star_Ratio = 0;
         Piercing_Line_Ratio = 0.5;
         Piercing_Candle_Length = 10;
         Engulfing_Length = 25;
         break;
      case 240:
         Doji_Star_Ratio = 0;
         Piercing_Line_Ratio = 0.5;
         Piercing_Candle_Length = 10;
         Engulfing_Length = 20;
         break;
      case 1440:
         Doji_Star_Ratio = 0;
         Piercing_Line_Ratio = 0.5;
         Piercing_Candle_Length = 10;
         Engulfing_Length = 30;
         break;
      case 10080:
         Doji_Star_Ratio = 0;
         Piercing_Line_Ratio = 0.5;
         Piercing_Candle_Length = 10;
         Engulfing_Length = 40;
         break;
      case 43200:
         Doji_Star_Ratio = 0;
         Piercing_Line_Ratio = 0.5;
         Piercing_Candle_Length = 10;
         Engulfing_Length = 50;
         break;
   }
   
      counter=shift;
      Range=0;
      AvgRange=0;
      for (counter=shift ;counter<=shift+9;counter++) {
         AvgRange=AvgRange+MathAbs(High[counter]-Low[counter]);
      }
      Range=AvgRange/10;
      shift1 = shift + 1;
      shift2 = shift + 2;
      shift3 = shift + 3;
      shift4 = shift + 4;
      
      
      O = Open[shift1];
      O1 = Open[shift2];
      O2 = Open[shift3];
      H = High[shift1];
      H1 = High[shift2];
      H2 = High[shift3];
      H3 = High[shift4];
      L = Low[shift1];
      L1 = Low[shift2];
      L2 = Low[shift3];
      L3 = Low[shift4];
      C = Close[shift1];
      C1 = Close[shift2];
      C2 = Close[shift3];
      C3 = Close[shift4];
      if (O>C) {
         BodyHigh = O;
         BodyLow = C;  }
      else {
         BodyHigh = C;
         BodyLow = O; }
      CL = High[shift1]-Low[shift1];
      CL1 = High[shift2]-Low[shift2];
      CL2 = High[shift3]-Low[shift3];
      BL = Open[shift1]-Close[shift1];
      UW = High[shift1]-BodyHigh;
      LW = BodyLow-Low[shift1];
      BLa = MathAbs(BL);
      BL90 = BLa*Candle_WickBody_Percent;
            
         
 // Bearish Patterns  
 
      // Check for Bearish Shooting ShootStar
      if ((H>=H1)&&(H>H2)&&(H>H3))  {
         if (UseShootingStar)  {
         if (((UW/2)>LW)&&(UW>(2*BL90))&&(CL>=(CandleLength*Point))&&(O!=C)&&((UW/3)<=LW)&&((UW/4)<=LW)/*&&(L>L1)&&(L>L2)*/)  {return true;}
         else if (((UW/3)>LW)&&(UW>(2*BL90))&&(CL>=(CandleLength*Point))&&(O!=C)&&((UW/4)<=LW)/*&&(L>L1)&&(L>L2)*/)  {return true;}
         else if (((UW/4)>LW)&&(UW>(2*BL90))&&(CL>=(CandleLength*Point))&&(O!=C)/*&&(L>L1)&&(L>L2)*/)  {return true;}
         else return false;  
         } else return false;
         
      }

      // Check for Evening Star pattern
      else if ((C2>O2)&&((C2-O2)/(0.001+H2-L2)>0.6)&&(C2<O1)&&(C1>O1)&&((H1-L1)>(3*(C1-O1)))&&(O>C)&&(O<O1)){
         if (UseStar) {
            return true;
         } else return false;
      }
      
      
      // Check for Evening Doji Star pattern
      else if (/*(L>O1)&&*/(O==C)&&((C2>O2)&&(C2-O2)/(0.001+H2-L2)>Doji_Star_Ratio)/*&&(C2<O1)*/&&(C1>O1)/*&&((H1-L1)>(3*(C1-O1)))*/&&(CL>=(Doji_MinLength*Point))) {
         if (UseDoji) {
            return true;
         } else return false;
      }
      
      // Check for a Dark Cloud Cover pattern
      else if ((C1>O1)&&(((C1+O1)/2)>C)&&(O>C)&&(O>C1)&&(C>O1)&&((O-C)/(0.001+(H-L))>0.6)) {
         if (UseDarkCloud) {   
            return true;
         } else return false;
      }
      
      // Check for a Three Outside Down pattern
      else if ((C2>O2)&&(O1>C1)&&(O1>=C2)&&(O2>=C1)&&((O1-C1)>(C2-O2))&&(O>C)&&(C<C1)) {
         if (Use3Outside) {   
            return true;
         } else return false;
      }
      
      // Check for Bearish Harami pattern
      else if ((C1>O1)&&(O>C)&&(O<=C1)&&(O1<=C)&&((O-C)<(C1-O1))) {
         if (UseHarami) {   
            return true;
         } else return false;
      }
      
      // Check for Three Inside Down pattern
      else if ((C2>O2)&&(O1>C1)&&(O1<=C2)&&(O2<=C1)&&((O1-C1)<(C2-O2))&&(O>C)&&(C<C1)&&(O<O1)) {
         if (Use3Inside) {   
            return true;
         } else return false;
      }

      // Check for Bearish Engulfing pattern
      else if ((C1>O1)&&(O>C)&&(O>=C1)&&(O1>=C)&&((O-C)>(C1-O1))) {
         if (UseEngulfing) {
            return true;
         } else return false;
      } else return false;
      
   } else return true;
}

bool isBWRedZone(int index)
{
  if (useBWZoneTrade) {
    if (ZoneMode == 1) {
      if(IndAC(index)==1 && IndAO(index)==1) {return true;} else return false;
    } else if (ZoneMode == 2) {
      if((IndAC(index)==1 && IndAO(index)==2) || (IndAC(index)==2 && IndAO(index)==1)) {return true;} else return false;
    } else if (ZoneMode == 3) {
      if(IndAC(index)==1 && IndAO(index)==1 && IndAC(index+1)==2 && IndAO(index+1)==2) {return true;} else return false;
    } else return false;
  } else return true;
}

bool isBWGreenZone(int index)
{
  if (useBWZoneTrade) {
    if (ZoneMode == 1) {
      if(IndAC(index)==2 && IndAO(index)==2) {return true;} else return false;
    } else if (ZoneMode == 2) {
      if((IndAC(index)==1 && IndAO(index)==2) || (IndAC(index)==2 && IndAO(index)==1)) {return true;} else return false;
    } else if (ZoneMode == 3) {
      if(IndAC(index)==2 && IndAO(index)==2 && IndAC(index+1)==1 && IndAO(index+1)==1) {return true;} else return false;
    } else return false;
  } else return true;
}
   
int IndAC(int Shift)
   {
     int DirectionAC;
     AC_0 = iAC(Symbol(),0,Shift);
     AC_1 = iAC(Symbol(),0,Shift-1);
     if(AC_0>AC_1) {DirectionAC = 1;} // Down
     if(AC_0<AC_1) {DirectionAC = 2;} // Up
     return(DirectionAC);
   }


int IndAO(int Shift)
   {
     int DirectionAO;
     AO_0 = iAO(Symbol(),0,Shift);
     AO_1 = iAO(Symbol(),0,Shift-1);
     if(AO_0>AO_1) {DirectionAO = 1;} // Down
     if(AO_0<AO_1) {DirectionAO = 2;} // Up
     return(DirectionAO);
   }

bool isUpTrend (int index)
{
   if (UseMATrendFilter)
   {
      if (iMA(NULL, 0, TrendFastPeriod, 0, 1, 0, index)>iMA(NULL, 0, TrendSlowPeriod, 0, 1, 0, index)) return true; else return false;
   } else return true;
}

bool isDownTrend (int index)
{
   if (UseMATrendFilter)
   {
      if (iMA(NULL, 0, TrendFastPeriod, 0, 1, 0, index)<iMA(NULL, 0, TrendSlowPeriod, 0, 1, 0, index)) return true; else return false;
   } else return true;
}

bool isRSIOverBought (int index)
{
  if (UseRSIFilter) 
  {
      if(iRSI(NULL,0,RSIPeriod,PRICE_CLOSE,index)>OverBoughtLevel) return true; else return false;
  } else return true;
}

bool isRSIOverSold (int index)
{
  if (UseRSIFilter) 
  {
      if(iRSI(NULL,0,RSIPeriod,PRICE_CLOSE,index)<OverSoldLevel) return true; else return false;
  } return true;
}

bool isStochCrossUp (int index)
{
  if (UseStochFilter) 
  {
      double stochastic1now, stochastic2now, stochastic1previous, stochastic2previous/*, stochastic1after, stochastic2after*/;
      stochastic1now=iStochastic(NULL,0,KPeriod,DPeriod,Slowing,MODE_SMA,0,MODE_MAIN,index);
      stochastic1previous=iStochastic(NULL,0,KPeriod,DPeriod,Slowing,MODE_SMA,0,MODE_MAIN,index+1);
      //stochastic1after=iStochastic(NULL,0,KPeriod,DPeriod,Slowing,MODE_SMA,0,MODE_MAIN,index-1);
      stochastic2now=iStochastic(NULL,0,KPeriod,DPeriod,Slowing,MODE_SMA,0,MODE_SIGNAL,index);
      stochastic2previous=iStochastic(NULL,0,KPeriod,DPeriod,Slowing,MODE_SMA,0,MODE_SIGNAL,index+1);
      //stochastic2after=iStochastic(NULL,0,KPeriod,DPeriod,Slowing,MODE_SMA,0,MODE_SIGNAL,index-1);
      if ((stochastic1now > stochastic2now) && (stochastic1previous < stochastic2previous) /*&& (stochastic1after > stochastic2after)*/) 
        {
         if (UseOBOSFilter) {
            if (stochastic1now < 30) {return true;} else {return false;}
         } else return true;
        } else return false;
  } else return true;
}

bool isStochCrossDown (int index)
{
  if (UseStochFilter) 
  {
      double stochastic1now, stochastic2now, stochastic1previous, stochastic2previous/*, stochastic1after, stochastic2after*/;
      stochastic1now=iStochastic(NULL,0,KPeriod,DPeriod,Slowing,MODE_SMA,0,MODE_MAIN,index);
      stochastic1previous=iStochastic(NULL,0,KPeriod,DPeriod,Slowing,MODE_SMA,0,MODE_MAIN,index+1);
      //stochastic1after=iStochastic(NULL,0,KPeriod,DPeriod,Slowing,MODE_SMA,0,MODE_MAIN,index-1);
      stochastic2now=iStochastic(NULL,0,KPeriod,DPeriod,Slowing,MODE_SMA,0,MODE_SIGNAL,index);
      stochastic2previous=iStochastic(NULL,0,KPeriod,DPeriod,Slowing,MODE_SMA,0,MODE_SIGNAL,index+1);
      //stochastic2after=iStochastic(NULL,0,KPeriod,DPeriod,Slowing,MODE_SMA,0,MODE_SIGNAL,index-1);
      if ((stochastic1now < stochastic2now) && (stochastic1previous > stochastic2previous) /*&& (stochastic1after < stochastic2after)*/)
        {
         if (UseOBOSFilter) {
            if (stochastic1now > 70) {return true;} else {return false;}
         } else return true;
        } else return false;
  } else return true;
}

//+------------------------------------------------------------------+
//| Method to calculate Upper Fractal                                |
//| Return Boolean (True/False)                                      |
//| If UseHighLowFilter set to false, this method always return True |
//+------------------------------------------------------------------+

bool isUpperFractal (int BarPeriod = 1)
{
      if (UseHighLowFilter)
      {
      int half = HighLowPeriod/2;

         bool   found     = true;
         double compareTo = iMA(NULL,0,1,0,MODE_SMA,PriceHigh,BarPeriod);
         for (int k=1;k<=half;k++)
            {
               if ((BarPeriod+k)<Bars && iMA(NULL,0,1,0,MODE_SMA,PriceHigh,BarPeriod+k)> compareTo) { found=false; break; }
               if (RepaintMode) {
                  if ((BarPeriod-k)>=0   && iMA(NULL,0,1,0,MODE_SMA,PriceHigh,BarPeriod-k)>=compareTo) {
                     // Print("k = "+k);
                     found=false; break;
                  }
               } else {
                  if (k==1   && iMA(NULL,0,1,0,MODE_SMA,PriceHigh,BarPeriod-k)>=compareTo) {
                     // Print("k = "+k);
                     found=false; break;
                  }
               }
            }
         if (found) 
               return true;
         else  return false;
     } else return true;
}

//+------------------------------------------------------------------+
//| Method to calculate Lower Fractal                                |
//| Return Boolean (True/False)                                      |
//| If UseHighLowFilter set to false, this method always return True |
//+------------------------------------------------------------------+

bool isLowerFractal (int BarPeriod = 1)
{
      if (UseHighLowFilter)
      {     
      int half = HighLowPeriod/2;
 
         bool found     = true;
         double compareTo = iMA(NULL,0,1,0,MODE_SMA,PriceLow,BarPeriod);
         for (int k=1;k<=half;k++)
            {
               if ((BarPeriod+k)<Bars && iMA(NULL,0,1,0,MODE_SMA,PriceLow,BarPeriod+k)< compareTo) { found=false; break; }
               if (RepaintMode) {
                  if ((BarPeriod-k)>=0   && iMA(NULL,0,1,0,MODE_SMA,PriceLow,BarPeriod-k)<=compareTo) { 
                     // Print("k = "+k);
                     found=false; break; 
                  }
               } else {
                  if (k==1   && iMA(NULL,0,1,0,MODE_SMA,PriceLow,BarPeriod-k)<=compareTo) { 
                     // Print("k = "+k);
                     found=false; break; 
                  }
               }
            }
         if (found)
              return true;
         else return false;
     } else return true;
}

//+------------------------------------------------------------------+
//| Method to determine if candle is new or not                      |
//| Useful to calculate indicator once only per candle               |
//+------------------------------------------------------------------+

bool isNewCandle (int index=0)
{
      static datetime saved_candle_time;
      if(Time[index]==saved_candle_time)
      {
         return false;
      } else {
         saved_candle_time=Time[index];
         return true;
      }
}

bool isNewCandleOnDate (int index=0)
{
      static datetime saved_candle_time;
      if(Time[index]==saved_candle_time)
      {
         return false;
      } else {
         saved_candle_time=Time[index];
         return true;
      }
}

//+------------------------------------------------------------------+
//| Method to know specific status on specific date                  |
//| Useful for in-depth on Date analysis                             |
//+------------------------------------------------------------------+

void getStatOnDate (datetime times, int& returnArray[])
{
   int limits, i, counter;
   int start;
   bool isUpTradeOnDate = false;
   bool isDownTradeOnDate = false;
   bool Prep_isUpTradeOnDate = false;
   bool Prep_isDownTradeOnDate = false;
   
   int tmpExpiryOnDate;
   tmpExpiryOnDate=expiryCandle;
   
   double tmp=0;
   double Range, AvgRange;
   int counted_bars=IndicatorCounted();
   
   if(counted_bars<0) return;
   
   int timeFrame;
   timeFrame = Period();

   int winOnDate = 0;
   int loseOnDate = 0;
   int totalOnDate = 0;

   datetime tomorrowIndex = times + 60 * 60 * 24;
   limits = iBarShift(NULL,Period(),times,false);
   start = iBarShift(NULL,Period(),tomorrowIndex,false);

   for(i = limits; i >= start; i--) {
   
      counter=i;
      Range=0;
      AvgRange=0;
      for (counter=i ;counter<=i+9;counter++)
      {
         AvgRange=AvgRange+MathAbs(High[counter]-Low[counter]);
      }
      Range=AvgRange/10;
       
      if (isUpTradeOnDate && isNewCandleOnDate(i) && tmpExpiryOnDate==0) 
      {
         if (Open[i]>CallStrikePrice(i+expiryCandle))
         {
            winOnDate++;
         } else {
            loseOnDate++;
         }
         
         isUpTradeOnDate=false;
      }
      
      if (isDownTradeOnDate && isNewCandleOnDate(i) && tmpExpiryOnDate==0) 
      {
         if (PutStrikePrice(i+expiryCandle)>Open[i])
         {
            winOnDate++;
         } else {
            loseOnDate++;
         }
         
         isDownTradeOnDate=false;
      }
      
      if (tmpExpiryOnDate==0 && isNewCandleOnDate(i))
      {
         tmpExpiryOnDate=expiryCandle;
      }

      if (SafeStrikePriceMode) {

         if (Low[i]<((Close[i+1])-MathAbs(StrikePriceIndex*(Open[i+1]-Close[i+1])/100)) && isBuySignal(i+1) && isNewCandleOnDate(i)) {
            if (ReverseMode) {
               totalOnDate++;
               if (tmpExpiryOnDate>0) {tmpExpiryOnDate--; Prep_isDownTradeOnDate=true;}
               if (tmpExpiryOnDate==0 && Prep_isDownTradeOnDate)
               {
                  isDownTradeOnDate=true;
                  Prep_isDownTradeOnDate=false;
               }
            } else {
               totalOnDate++;
               if (tmpExpiryOnDate>0) {tmpExpiryOnDate--; Prep_isUpTradeOnDate=true;}
               if (tmpExpiryOnDate==0 && Prep_isUpTradeOnDate)
               {
                  isUpTradeOnDate=true;
                  Prep_isUpTradeOnDate=false;
               }
            }
         }
         
         if (High[i]>((Close[i+1])+MathAbs(StrikePriceIndex*(Open[i+1]-Close[i+1])/100)) && isSellSignal(i+1) && isNewCandleOnDate(i)) {
            if (ReverseMode) {
               totalOnDate++;
               if (tmpExpiryOnDate>0) {tmpExpiryOnDate--; Prep_isUpTradeOnDate=true;}
               if (tmpExpiryOnDate==0 && Prep_isUpTradeOnDate)
               {
                  isUpTradeOnDate=true;
                  Prep_isUpTradeOnDate=false;
               }
            } else {
               totalOnDate++;
               if (tmpExpiryOnDate>0) {tmpExpiryOnDate--; Prep_isDownTradeOnDate=true;}
               if (tmpExpiryOnDate==0 && Prep_isDownTradeOnDate)
               {
                  isDownTradeOnDate=true;
                  Prep_isDownTradeOnDate=false;
               }
            }
         }
         
         if(Prep_isUpTradeOnDate && isNewCandleOnDate(i)) 
         {
            if (tmpExpiryOnDate==expiryCandle) {totalOnDate++;}
            if (tmpExpiryOnDate>0 && Prep_isUpTradeOnDate) {tmpExpiryOnDate--;}
            if (tmpExpiryOnDate==0 && Prep_isUpTradeOnDate)
            {
               isUpTradeOnDate=true;
               Prep_isUpTradeOnDate=false;
            }
         }
         
         if(Prep_isDownTradeOnDate && isNewCandleOnDate(i)) 
         {
            if (tmpExpiryOnDate==expiryCandle) {totalOnDate++;}
            if (tmpExpiryOnDate>0 && Prep_isDownTradeOnDate) {tmpExpiryOnDate--;}
            if (tmpExpiryOnDate==0 && Prep_isDownTradeOnDate)
            {
               isDownTradeOnDate=true;
               Prep_isDownTradeOnDate=false;
            }
         }

      } else {
      
         if(Prep_isUpTradeOnDate && isNewCandleOnDate(i)) 
         {
            if (tmpExpiryOnDate==expiryCandle) {totalOnDate++;}
            if (tmpExpiryOnDate>0 && Prep_isUpTradeOnDate) {tmpExpiryOnDate--;}
            if (tmpExpiryOnDate==0 && Prep_isUpTradeOnDate)
            {
               isUpTradeOnDate=true;
               Prep_isUpTradeOnDate=false;
            }
         }
         
         if(Prep_isDownTradeOnDate && isNewCandleOnDate(i)) 
         {
            if (tmpExpiryOnDate==expiryCandle) {totalOnDate++;}
            if (tmpExpiryOnDate>0 && Prep_isDownTradeOnDate) {tmpExpiryOnDate--;}
            if (tmpExpiryOnDate==0 && Prep_isDownTradeOnDate)
            {
               isDownTradeOnDate=true;
               Prep_isDownTradeOnDate=false;
            }
         }
      }
           
      if (isBuySignal(i) && isNewCandleOnDate(i)) //make sure isNewCandleOnDate is on the last order
      {
         if (ReverseMode)
         {
            if (SafeStrikePriceMode==false) {Prep_isDownTradeOnDate=true;}
         } else {
            if (SafeStrikePriceMode==false) {Prep_isUpTradeOnDate=true;}
         }
      }
      else if (isSellSignal(i) && isNewCandleOnDate(i)) //make sure isNewCandleOnDate is on the last order
      {     
         if (ReverseMode)
         {
            if (SafeStrikePriceMode==false) {Prep_isUpTradeOnDate=true;}
         } else {
            if (SafeStrikePriceMode==false) {Prep_isDownTradeOnDate=true;}
         }
      }
   }
   
   returnArray[0]=winOnDate;
   returnArray[1]=loseOnDate;
   returnArray[2]=totalOnDate;
}

void getCompleteStatOnDate (datetime times, int& returnArray[])
{
   int limits, i, counter;
   int start;
   bool isUpTradeOnDate = false;
   bool isDownTradeOnDate = false;
   bool Prep_isUpTradeOnDate = false;
   bool Prep_isDownTradeOnDate = false;
   
   int tmpExpiryOnDate;
   tmpExpiryOnDate=expiryCandle;
   
   double tmp=0;
   double Range, AvgRange;
   int counted_bars=IndicatorCounted();
   
   if(counted_bars<0) return;
   
   int timeFrame;
   timeFrame = Period();

   int bufferMaxWinOnDate;
   int MaxWinOnDate;
   int bufferMaxLoseOnDate;
   int MaxLoseOnDate;
   int MaxWinOnDateDelayBuffer=ConsecutiveDelayIndex;
   int MaxLoseOnDateDelayBuffer=ConsecutiveDelayIndex;
   int MaxLoseTimeOnDate;
   int MaxWinTimeOnDate;

   int notSafeWinUpOnDate;
   int notSafeLoseUpOnDate;
   int notSafeWinDownOnDate;
   int notSafeLoseDownOnDate;

   int winOnDate = 0;
   int loseOnDate = 0;
   int totalOnDate = 0;

   datetime tomorrowIndex = times + 60 * 60 * 24;
   limits = iBarShift(NULL,Period(),times,false);
   start = iBarShift(NULL,Period(),tomorrowIndex,false);

   for(i = limits; i >= start; i--) {
   
      counter=i;
      Range=0;
      AvgRange=0;
      for (counter=i ;counter<=i+9;counter++)
      {
         AvgRange=AvgRange+MathAbs(High[counter]-Low[counter]);
      }
      Range=AvgRange/10;
       
      if (isUpTradeOnDate && isNewCandleOnDate(i) && tmpExpiryOnDate==0) 
      {
         if (Open[i]>CallStrikePrice(i+expiryCandle))
         {
            winOnDate++;
            bufferMaxWinOnDate++;
            if (MaxLoseOnDateDelayBuffer==0) {
               MaxLoseOnDateDelayBuffer=ConsecutiveDelayIndex;
               if (bufferMaxLoseOnDate>MaxLoseOnDate) {MaxLoseOnDate=bufferMaxLoseOnDate; bufferMaxLoseOnDate=0; MaxLoseTimeOnDate=Time[i];} else {bufferMaxLoseOnDate=0;}
            } else {MaxLoseOnDateDelayBuffer--;}
         if (MathAbs(Open[i]-CallStrikePrice(i+expiryCandle))<MathAbs(NotSafeIndex*(Open[i+1+expiryCandle]-CallStrikePrice(i+expiryCandle))/100)) {notSafeWinUpOnDate++;}
         } else {
            loseOnDate++;
            bufferMaxLoseOnDate++;
            if (MaxWinOnDateDelayBuffer==0) {
               MaxWinOnDateDelayBuffer=ConsecutiveDelayIndex;
               if (bufferMaxWinOnDate>MaxWinOnDate) {MaxWinOnDate=bufferMaxWinOnDate; bufferMaxWinOnDate=0; MaxWinTimeOnDate=Time[i];} else {bufferMaxWinOnDate=0;}
            } else {MaxWinOnDateDelayBuffer--;}
         if (MathAbs(Open[i]-CallStrikePrice(i+expiryCandle))<MathAbs(NotSafeIndex*(Open[i+1+expiryCandle]-CallStrikePrice(i+expiryCandle))/100)) {notSafeLoseUpOnDate++;}
         }
         
         isUpTradeOnDate=false;
      }
      
      if (isDownTradeOnDate && isNewCandleOnDate(i) && tmpExpiryOnDate==0) 
      {
         if (PutStrikePrice(i+expiryCandle)>Open[i])
         {
            winOnDate++;
            bufferMaxWinOnDate++;
            if (MaxLoseOnDateDelayBuffer==0) {
               MaxLoseOnDateDelayBuffer=ConsecutiveDelayIndex;
               if (bufferMaxLoseOnDate>MaxLoseOnDate) {MaxLoseOnDate=bufferMaxLoseOnDate; bufferMaxLoseOnDate=0; MaxLoseTimeOnDate=Time[i];} else {bufferMaxLoseOnDate=0;}
            } else {MaxLoseOnDateDelayBuffer--;}
         if (MathAbs(Open[i]-PutStrikePrice(i+expiryCandle))<MathAbs(NotSafeIndex*(Open[i+1+expiryCandle]-PutStrikePrice(i+expiryCandle))/100)) {notSafeWinDownOnDate++;}
         } else {
            loseOnDate++;
            bufferMaxLoseOnDate++;
            if (MaxWinOnDateDelayBuffer==0) {
               MaxWinOnDateDelayBuffer=ConsecutiveDelayIndex;
               if (bufferMaxWinOnDate>MaxWinOnDate) {MaxWinOnDate=bufferMaxWinOnDate; bufferMaxWinOnDate=0; MaxWinTimeOnDate=Time[i];} else {bufferMaxWinOnDate=0;}
            } else {MaxWinOnDateDelayBuffer--;}
         if (MathAbs(Open[i]-PutStrikePrice(i+expiryCandle))<MathAbs(NotSafeIndex*(Open[i+1+expiryCandle]-PutStrikePrice(i+expiryCandle))/100)) {notSafeLoseDownOnDate++;}
         }
         
         isDownTradeOnDate=false;
      }
      
      if (tmpExpiryOnDate==0 && isNewCandleOnDate(i))
      {
         tmpExpiryOnDate=expiryCandle;
      }
      
      if (SafeStrikePriceMode) {

         if (Low[i]<((Close[i+1])-MathAbs(StrikePriceIndex*(Open[i+1]-Close[i+1])/100)) && isBuySignal(i+1) && isNewCandleOnDate(i)) {
            if (ReverseMode) {
               totalOnDate++;
               if (tmpExpiryOnDate>0) {tmpExpiryOnDate--; Prep_isDownTradeOnDate=true;}
               if (tmpExpiryOnDate==0 && Prep_isDownTradeOnDate)
               {
                  isDownTradeOnDate=true;
                  Prep_isDownTradeOnDate=false;
               }
            } else {
               totalOnDate++;
               if (tmpExpiryOnDate>0) {tmpExpiryOnDate--; Prep_isUpTradeOnDate=true;}
               if (tmpExpiryOnDate==0 && Prep_isUpTradeOnDate)
               {
                  isUpTradeOnDate=true;
                  Prep_isUpTradeOnDate=false;
               }
            }
         }
         
         if (High[i]>((Close[i+1])+MathAbs(StrikePriceIndex*(Open[i+1]-Close[i+1])/100)) && isSellSignal(i+1) && isNewCandleOnDate(i)) {
            if (ReverseMode) {
               totalOnDate++;
               if (tmpExpiryOnDate>0) {tmpExpiryOnDate--; Prep_isUpTradeOnDate=true;}
               if (tmpExpiryOnDate==0 && Prep_isUpTradeOnDate)
               {
                  isUpTradeOnDate=true;
                  Prep_isUpTradeOnDate=false;
               }
            } else {
               totalOnDate++;
               if (tmpExpiryOnDate>0) {tmpExpiryOnDate--; Prep_isDownTradeOnDate=true;}
               if (tmpExpiryOnDate==0 && Prep_isDownTradeOnDate)
               {
                  isDownTradeOnDate=true;
                  Prep_isDownTradeOnDate=false;
               }
            }
         }
         
         if(Prep_isUpTradeOnDate && isNewCandleOnDate(i)) 
         {
            if (tmpExpiryOnDate==expiryCandle) {totalOnDate++;}
            if (tmpExpiryOnDate>0 && Prep_isUpTradeOnDate) {tmpExpiryOnDate--;}
            if (tmpExpiryOnDate==0 && Prep_isUpTradeOnDate)
            {
               isUpTradeOnDate=true;
               Prep_isUpTradeOnDate=false;
            }
         }
         
         if(Prep_isDownTradeOnDate && isNewCandleOnDate(i)) 
         {
            if (tmpExpiryOnDate==expiryCandle) {totalOnDate++;}
            if (tmpExpiryOnDate>0 && Prep_isDownTradeOnDate) {tmpExpiryOnDate--;}
            if (tmpExpiryOnDate==0 && Prep_isDownTradeOnDate)
            {
               isDownTradeOnDate=true;
               Prep_isDownTradeOnDate=false;
            }
         }

      } else {
      
         if(Prep_isUpTradeOnDate && isNewCandleOnDate(i)) 
         {
            if (tmpExpiryOnDate==expiryCandle) {totalOnDate++;}
            if (tmpExpiryOnDate>0 && Prep_isUpTradeOnDate) {tmpExpiryOnDate--;}
            if (tmpExpiryOnDate==0 && Prep_isUpTradeOnDate)
            {
               isUpTradeOnDate=true;
               Prep_isUpTradeOnDate=false;
            }
         }
         
         if(Prep_isDownTradeOnDate && isNewCandleOnDate(i)) 
         {
            if (tmpExpiryOnDate==expiryCandle) {totalOnDate++;}
            if (tmpExpiryOnDate>0 && Prep_isDownTradeOnDate) {tmpExpiryOnDate--;}
            if (tmpExpiryOnDate==0 && Prep_isDownTradeOnDate)
            {
               isDownTradeOnDate=true;
               Prep_isDownTradeOnDate=false;
            }
         }
      }
           
      if (isBuySignal(i) && isNewCandleOnDate(i)) //make sure isNewCandleOnDate is on the last order
      {
         if (ReverseMode)
         {
            if (SafeStrikePriceMode==false) {Prep_isDownTradeOnDate=true;}
         } else {
            if (SafeStrikePriceMode==false) {Prep_isUpTradeOnDate=true;}
         }
      }
      else if (isSellSignal(i) && isNewCandleOnDate(i)) //make sure isNewCandleOnDate is on the last order
      {     
         if (ReverseMode)
         {
            if (SafeStrikePriceMode==false) {Prep_isUpTradeOnDate=true;}
         } else {
            if (SafeStrikePriceMode==false) {Prep_isDownTradeOnDate=true;}
         }
      }
   }
   
   returnArray[0]=winOnDate;
   returnArray[1]=loseOnDate;
   returnArray[2]=totalOnDate;
   returnArray[3]=MaxWinOnDate;
   returnArray[4]=MaxLoseOnDate;
   returnArray[5]=notSafeWinUpOnDate;
   returnArray[6]=notSafeWinDownOnDate;
   returnArray[7]=notSafeLoseUpOnDate;
   returnArray[8]=notSafeLoseDownOnDate;
   returnArray[9]=MaxLoseTimeOnDate;
   returnArray[10]=MaxWinTimeOnDate;
}

void getAdditionalStatOnDate (datetime times, int& returnArray[])
{
   int limits, i, counter;
   int start;
   bool isUpTradeOnDate = false;
   bool isDownTradeOnDate = false;
   bool Prep_isUpTradeOnDate = false;
   bool Prep_isDownTradeOnDate = false;
   
   int tmpExpiryOnDate;
   tmpExpiryOnDate=expiryCandle;
   
   double tmp=0;
   double Range, AvgRange;
   int counted_bars=IndicatorCounted();
   
   if(counted_bars<0) return;
   
   int timeFrame;
   timeFrame = Period();

   int bufferMaxWinOnDate;
   int MaxWinOnDate;
   int bufferMaxLoseOnDate;
   int MaxLoseOnDate;
   int MaxWinOnDateDelayBuffer=ConsecutiveDelayIndex;
   int MaxLoseOnDateDelayBuffer=ConsecutiveDelayIndex;
   int MaxLoseTimeOnDate;

   int notSafeWinUpOnDate;
   int notSafeLoseUpOnDate;
   int notSafeWinDownOnDate;
   int notSafeLoseDownOnDate;

   datetime tomorrowIndex = times + 60 * 60 * 24;
   limits = iBarShift(NULL,Period(),times,false);
   start = iBarShift(NULL,Period(),tomorrowIndex,false);

   for(i = limits; i >= start; i--) {
   
      counter=i;
      Range=0;
      AvgRange=0;
      for (counter=i ;counter<=i+9;counter++)
      {
         AvgRange=AvgRange+MathAbs(High[counter]-Low[counter]);
      }
      Range=AvgRange/10;
       
      if (isUpTradeOnDate && isNewCandleOnDate(i) && tmpExpiryOnDate==0) 
      {
         if (Open[i]>CallStrikePrice(i+expiryCandle))
         {
            bufferMaxWinOnDate++;
            if (MaxLoseOnDateDelayBuffer==0) {
               MaxLoseOnDateDelayBuffer=ConsecutiveDelayIndex;
               if (bufferMaxLoseOnDate>MaxLoseOnDate) {MaxLoseOnDate=bufferMaxLoseOnDate; bufferMaxLoseOnDate=0; MaxLoseTimeOnDate=Time[i];} else {bufferMaxLoseOnDate=0;}
            } else {MaxLoseOnDateDelayBuffer--;}
         if (MathAbs(Open[i]-CallStrikePrice(i+expiryCandle))<MathAbs(NotSafeIndex*(Open[i+1+expiryCandle]-CallStrikePrice(i+expiryCandle))/100)) {notSafeWinUpOnDate++;}
         } else {
            bufferMaxLoseOnDate++;
            if (MaxWinOnDateDelayBuffer==0) {
               MaxWinOnDateDelayBuffer=ConsecutiveDelayIndex;
               if (bufferMaxWinOnDate>MaxWinOnDate) {MaxWinOnDate=bufferMaxWinOnDate; bufferMaxWinOnDate=0;} else {bufferMaxWinOnDate=0;}
            } else {MaxWinOnDateDelayBuffer--;}
         if (MathAbs(Open[i]-CallStrikePrice(i+expiryCandle))<MathAbs(NotSafeIndex*(Open[i+1+expiryCandle]-CallStrikePrice(i+expiryCandle))/100)) {notSafeLoseUpOnDate++;}
         }
         
         isUpTradeOnDate=false;
      }
      
      if (isDownTradeOnDate && isNewCandleOnDate(i) && tmpExpiryOnDate==0) 
      {
         if (PutStrikePrice(i+expiryCandle)>Open[i])
         {
            bufferMaxWinOnDate++;
            if (MaxLoseOnDateDelayBuffer==0) {
               MaxLoseOnDateDelayBuffer=ConsecutiveDelayIndex;
               if (bufferMaxLoseOnDate>MaxLoseOnDate) {MaxLoseOnDate=bufferMaxLoseOnDate; bufferMaxLoseOnDate=0; MaxLoseTimeOnDate=Time[i];} else {bufferMaxLoseOnDate=0;}
            } else {MaxLoseOnDateDelayBuffer--;}
         if (MathAbs(Open[i]-PutStrikePrice(i+expiryCandle))<MathAbs(NotSafeIndex*(Open[i+1+expiryCandle]-PutStrikePrice(i+expiryCandle))/100)) {notSafeWinDownOnDate++;}
         } else {
            bufferMaxLoseOnDate++;
            if (MaxWinOnDateDelayBuffer==0) {
               MaxWinOnDateDelayBuffer=ConsecutiveDelayIndex;
               if (bufferMaxWinOnDate>MaxWinOnDate) {MaxWinOnDate=bufferMaxWinOnDate; bufferMaxWinOnDate=0;} else {bufferMaxWinOnDate=0;}
            } else {MaxWinOnDateDelayBuffer--;}
         if (MathAbs(Open[i]-PutStrikePrice(i+expiryCandle))<MathAbs(NotSafeIndex*(Open[i+1+expiryCandle]-PutStrikePrice(i+expiryCandle))/100)) {notSafeLoseDownOnDate++;}
         }
         
         isDownTradeOnDate=false;
      }
      
      if (tmpExpiryOnDate==0 && isNewCandleOnDate(i))
      {
         tmpExpiryOnDate=expiryCandle;
      }
      
      if (SafeStrikePriceMode) {

         if (Low[i]<((Close[i+1])-MathAbs(StrikePriceIndex*(Open[i+1]-Close[i+1])/100)) && isBuySignal(i+1) && isNewCandleOnDate(i)) {
            if (ReverseMode) {
               if (tmpExpiryOnDate>0) {tmpExpiryOnDate--; Prep_isDownTradeOnDate=true;}
               if (tmpExpiryOnDate==0 && Prep_isDownTradeOnDate)
               {
                  isDownTradeOnDate=true;
                  Prep_isDownTradeOnDate=false;
               }
            } else {
               if (tmpExpiryOnDate>0) {tmpExpiryOnDate--; Prep_isUpTradeOnDate=true;}
               if (tmpExpiryOnDate==0 && Prep_isUpTradeOnDate)
               {
                  isUpTradeOnDate=true;
                  Prep_isUpTradeOnDate=false;
               }
            }
         }
         
         if (High[i]>((Close[i+1])+MathAbs(StrikePriceIndex*(Open[i+1]-Close[i+1])/100)) && isSellSignal(i+1) && isNewCandleOnDate(i)) {
            if (ReverseMode) {
               if (tmpExpiryOnDate>0) {tmpExpiryOnDate--; Prep_isUpTradeOnDate=true;}
               if (tmpExpiryOnDate==0 && Prep_isUpTradeOnDate)
               {
                  isUpTradeOnDate=true;
                  Prep_isUpTradeOnDate=false;
               }
            } else {
               if (tmpExpiryOnDate>0) {tmpExpiryOnDate--; Prep_isDownTradeOnDate=true;}
               if (tmpExpiryOnDate==0 && Prep_isDownTradeOnDate)
               {
                  isDownTradeOnDate=true;
                  Prep_isDownTradeOnDate=false;
               }
            }
         }
         
         if(Prep_isUpTradeOnDate && isNewCandleOnDate(i)) 
         {
            if (tmpExpiryOnDate>0 && Prep_isUpTradeOnDate) {tmpExpiryOnDate--;}
            if (tmpExpiryOnDate==0 && Prep_isUpTradeOnDate)
            {
               isUpTradeOnDate=true;
               Prep_isUpTradeOnDate=false;
            }
         }
         
         if(Prep_isDownTradeOnDate && isNewCandleOnDate(i)) 
         {
            if (tmpExpiryOnDate>0 && Prep_isDownTradeOnDate) {tmpExpiryOnDate--;}
            if (tmpExpiryOnDate==0 && Prep_isDownTradeOnDate)
            {
               isDownTradeOnDate=true;
               Prep_isDownTradeOnDate=false;
            }
         }

      } else {
      
         if(Prep_isUpTradeOnDate && isNewCandleOnDate(i)) 
         {
            if (tmpExpiryOnDate>0 && Prep_isUpTradeOnDate) {tmpExpiryOnDate--;}
            if (tmpExpiryOnDate==0 && Prep_isUpTradeOnDate)
            {
               isUpTradeOnDate=true;
               Prep_isUpTradeOnDate=false;
            }
         }
         
         if(Prep_isDownTradeOnDate && isNewCandleOnDate(i)) 
         {
            if (tmpExpiryOnDate>0 && Prep_isDownTradeOnDate) {tmpExpiryOnDate--;}
            if (tmpExpiryOnDate==0 && Prep_isDownTradeOnDate)
            {
               isDownTradeOnDate=true;
               Prep_isDownTradeOnDate=false;
            }
         }
      }
           
      if (isBuySignal(i) && isNewCandleOnDate(i)) //make sure isNewCandleOnDate is on the last order
      {
         if (ReverseMode)
         {
            if (SafeStrikePriceMode==false) {Prep_isDownTradeOnDate=true;}
         } else {
            if (SafeStrikePriceMode==false) {Prep_isUpTradeOnDate=true;}
         }
      }
      else if (isSellSignal(i) && isNewCandleOnDate(i)) //make sure isNewCandleOnDate is on the last order
      {     
         if (ReverseMode)
         {
            if (SafeStrikePriceMode==false) {Prep_isUpTradeOnDate=true;}
         } else {
            if (SafeStrikePriceMode==false) {Prep_isDownTradeOnDate=true;}
         }
      }
   }
   
   returnArray[0]=MaxWinOnDate;
   returnArray[1]=MaxLoseOnDate;
   returnArray[2]=notSafeWinUpOnDate;
   returnArray[3]=notSafeWinDownOnDate;
   returnArray[4]=notSafeLoseUpOnDate;
   returnArray[5]=notSafeLoseDownOnDate;
   returnArray[6]=MaxLoseTimeOnDate;
}

void DrawYesterdayRowTitle (int Coloumn, int Buffer)
{
      // Yesterday Indicator Statistics
      double ColoumnBuffer;
      ColoumnBuffer=Coloumn-1;
   	ObjectCreate ("ydaytitle"+IntegerToString(Coloumn), OBJ_LABEL, 0, 0, 0);
      ObjectSetText ("ydaytitle"+IntegerToString(Coloumn),"|        Date      | W  |  L  |   T  |    WR     ",8,"Arial", White);
      ObjectSet ("ydaytitle"+IntegerToString(Coloumn), OBJPROP_CORNER, 3);
      ObjectSet ("ydaytitle"+IntegerToString(Coloumn), OBJPROP_XDISTANCE, ((ColoumnBuffer*180)+10));
      ObjectSet ("ydaytitle"+IntegerToString(Coloumn), OBJPROP_YDISTANCE,10+(Buffer*15));
   
      ObjectCreate ("ydayline1"+IntegerToString(Coloumn), OBJ_LABEL, 0, 0, 0);
      ObjectSetText ("ydayline1"+IntegerToString(Coloumn),"+-----------------------------------------+",8,"Arial", White);
      ObjectSet ("ydayline1"+IntegerToString(Coloumn), OBJPROP_CORNER, 3);
      ObjectSet ("ydayline1"+IntegerToString(Coloumn), OBJPROP_XDISTANCE, ((ColoumnBuffer*180)+10));
      ObjectSet ("ydayline1"+IntegerToString(Coloumn), OBJPROP_YDISTANCE,22+(Buffer*15));
         
      ObjectCreate ("ydayline2"+IntegerToString(Coloumn), OBJ_LABEL, 0, 0, 0);
      ObjectSetText ("ydayline2"+IntegerToString(Coloumn),"+-----------------------------------------+",8,"Arial", White);
      ObjectSet ("ydayline2"+IntegerToString(Coloumn), OBJPROP_CORNER, 3);
      ObjectSet ("ydayline2"+IntegerToString(Coloumn), OBJPROP_XDISTANCE, ((ColoumnBuffer*180)+10));
      ObjectSet ("ydayline2"+IntegerToString(Coloumn), OBJPROP_YDISTANCE,1+(Buffer*15));
}

void DrawAdditionalYesterdayRowTitle (int Coloumn, int Buffer)
{
      // Yesterday Indicator Statistics
      double ColoumnBuffer;
      ColoumnBuffer=Coloumn-1;
   	ObjectCreate ("ydaytitle"+IntegerToString(Coloumn), OBJ_LABEL, 0, 0, 0);
      ObjectSetText ("ydaytitle"+IntegerToString(Coloumn),"|          Date         |  NSW | NSL | CW | CL  | CLTime",6,"Arial", White);
      ObjectSet ("ydaytitle"+IntegerToString(Coloumn), OBJPROP_CORNER, 3);
      ObjectSet ("ydaytitle"+IntegerToString(Coloumn), OBJPROP_XDISTANCE, ((ColoumnBuffer*180)+10));
      ObjectSet ("ydaytitle"+IntegerToString(Coloumn), OBJPROP_YDISTANCE,11+(Buffer*15));
   
      ObjectCreate ("ydayline1"+IntegerToString(Coloumn), OBJ_LABEL, 0, 0, 0);
      ObjectSetText ("ydayline1"+IntegerToString(Coloumn),"+-----------------------------------------+",8,"Arial", White);
      ObjectSet ("ydayline1"+IntegerToString(Coloumn), OBJPROP_CORNER, 3);
      ObjectSet ("ydayline1"+IntegerToString(Coloumn), OBJPROP_XDISTANCE, ((ColoumnBuffer*180)+10));
      ObjectSet ("ydayline1"+IntegerToString(Coloumn), OBJPROP_YDISTANCE,20+(Buffer*15));
         
      ObjectCreate ("ydayline2"+IntegerToString(Coloumn), OBJ_LABEL, 0, 0, 0);
      ObjectSetText ("ydayline2"+IntegerToString(Coloumn),"+-----------------------------------------+",8,"Arial", White);
      ObjectSet ("ydayline2"+IntegerToString(Coloumn), OBJPROP_CORNER, 3);
      ObjectSet ("ydayline2"+IntegerToString(Coloumn), OBJPROP_XDISTANCE, ((ColoumnBuffer*180)+10));
      ObjectSet ("ydayline2"+IntegerToString(Coloumn), OBJPROP_YDISTANCE,1+(Buffer*15));
}

//+------------------------------------------------------------------+
//| LSMA with PriceMode  and isMACrossUp/Down                                             |
//| PrMode  0=close, 1=open, 2=high, 3=low, 4=median(high+low)/2,    |
//| 5=typical(high+low+close)/3, 6=weighted(high+low+close+close)/4  |
//+------------------------------------------------------------------+
bool isMACrossUp (int index)
{
  if (UseMACross)
  {
      double fastMAnow, slowMAnow, fastMAprevious, slowMAprevious;
      if (FastMA_Mode == 4)
      {
         fastMAnow = LSMA(FastMA_Period, FastPriceMode, index);
         fastMAprevious = LSMA(FastMA_Period, FastPriceMode,  index+1);
      }
      else
      {
         fastMAnow = iMA(NULL, 0, FastMA_Period, 0, FastMA_Mode, FastPriceMode, index);
         fastMAprevious = iMA(NULL, 0, FastMA_Period, 0, FastMA_Mode, FastPriceMode, index+1);
      }

      if (SlowMA_Mode == 4)
      {
         slowMAnow = LSMA( SlowMA_Period, SlowPriceMode, index);
         slowMAprevious = LSMA( SlowMA_Period, SlowPriceMode, index+1);
      }
      else
      {
         slowMAnow = iMA(NULL, 0, SlowMA_Period, 0, SlowMA_Mode, SlowPriceMode, index);
         slowMAprevious = iMA(NULL, 0, SlowMA_Period, 0, SlowMA_Mode, SlowPriceMode, index+1);
      }
      if ((fastMAnow > slowMAnow) && (fastMAprevious < slowMAprevious)) return true; else return false;
  } else return true;
}

bool isMACrossDown (int index)
{
  if (UseMACross)
  {
      double fastMAnow, slowMAnow, fastMAprevious, slowMAprevious;
      if (FastMA_Mode == 4)
      {
         fastMAnow = LSMA(FastMA_Period, FastPriceMode, index);
         fastMAprevious = LSMA(FastMA_Period, FastPriceMode,  index+1);
      }
      else
      {
         fastMAnow = iMA(NULL, 0, FastMA_Period, 0, FastMA_Mode, FastPriceMode, index);
         fastMAprevious = iMA(NULL, 0, FastMA_Period, 0, FastMA_Mode, FastPriceMode, index+1);
      }

      if (SlowMA_Mode == 4)
      {
         slowMAnow = LSMA( SlowMA_Period, SlowPriceMode, index);
         slowMAprevious = LSMA( SlowMA_Period, SlowPriceMode, index+1);
      }
      else
      {
         slowMAnow = iMA(NULL, 0, SlowMA_Period, 0, SlowMA_Mode, SlowPriceMode, index);
         slowMAprevious = iMA(NULL, 0, SlowMA_Period, 0, SlowMA_Mode, SlowPriceMode, index+1);
      }
      if ((fastMAnow < slowMAnow) && (fastMAprevious > slowMAprevious)) return true; else return false;
  } else return true;
}

double LSMA(int Rperiod, int prMode, int shift)
{
   int i;
   double sum, pr;
   int length;
   double lengthvar;
   double tmp;
   double wt;

   length = Rperiod;
 
   sum = 0;
   for(i = length; i >= 1  ; i--)
   {
     lengthvar = length + 1;
     lengthvar /= 3;
     tmp = 0;
     switch (prMode)
     {
     case 0: pr = Close[length-i+shift];break;
     case 1: pr = Open[length-i+shift];break;
     case 2: pr = High[length-i+shift];break;
     case 3: pr = Low[length-i+shift];break;
     case 4: pr = (High[length-i+shift] + Low[length-i+shift])/2;break;
     case 5: pr = (High[length-i+shift] + Low[length-i+shift] + Close[length-i+shift])/3;break;
     case 6: pr = (High[length-i+shift] + Low[length-i+shift] + Close[length-i+shift] + Close[length-i+shift])/4;break;
     }
     tmp = ( i - lengthvar)*pr;
     sum+=tmp;
    }
    wt = sum*6/(length*(length+1));
    
    return(wt);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start() {  

   //+------------------------------------------------------------------+
   //| Draw Pivot Level if setting true                                 |
   //+------------------------------------------------------------------+
   for(shiftBars=CountPeriods-1;shiftBars>=0;shiftBars--)
   {
      timestart = iTime(NULL,TimePeriod,shiftBars);
      timeend   = iTime(NULL,TimePeriod,shiftBars)+TimePeriod*60;   
         
      //if (UsePivotFilter) {CalculatePivotLevel(shiftBars+1,PivotLevelRange,PivotLevelArray);}
      if (DrawPivotLevel) { LevelsDraw(shiftBars+1,timestart,timeend,period+shiftBars); }               
   }
   
   //+------------------------------------------------------------------+
   //| Indicator Main Function Start Here                               |
   //+------------------------------------------------------------------+
   int limit, i, counter;
   int start = 0;
   color L_Color;
   currentDate=Day();
   
   double tmp=0;
   double Range, AvgRange;
   int counted_bars=IndicatorCounted();
   
   //---- check for possible errors
   if(counted_bars<0) return(-1);
   //---- last counted bar will be recounted
   //if(counted_bars>0) counted_bars--;
   
   int timeFrame;
   timeFrame = Period();
   
   if (CalculateOnlyOneDay) 
   {
      if (timeFrame==1) {limit=1440-counted_bars;}
      else if (timeFrame==5) {limit=288-counted_bars;}
      else if (timeFrame==15) {limit=96-counted_bars;}
      else if (timeFrame==30) {limit=48-counted_bars;}
      else if (timeFrame==60) {limit=24-counted_bars;}
      else if (timeFrame>61) {limit=1-counted_bars;}
   } else {limit=Bars-1-counted_bars;}
   
   for(i = limit; i >= start; i--) {
   
      counter=i;
      Range=0;
      AvgRange=0;
      for (counter=i ;counter<=i+9;counter++)
      {
         AvgRange=AvgRange+MathAbs(High[counter]-Low[counter]);
      }
      Range=AvgRange/10;
       
      if (isUpTrade && isNewCandle(i) && tmpExpiry==0) 
      {
         if (Open[i]>CallStrikePrice(i+expiryCandle))
         {
            sumWin++;
            bufferMaxWin++;
            if (MaxLoseDelayBuffer==0) {
               MaxLoseDelayBuffer=ConsecutiveDelayIndex;
               if (bufferMaxLose>MaxLose) {MaxLose=bufferMaxLose; bufferMaxLose=0; MaxLoseDate=TimeToStr(Time[i]);} else {bufferMaxLose=0;}
            } else {MaxLoseDelayBuffer--;}
            if (MathAbs(Open[i]-CallStrikePrice(i+expiryCandle))<MathAbs(NotSafeIndex*(Open[i+1+expiryCandle]-CallStrikePrice(i+expiryCandle))/100)) {notSafeWinUp++; L_Color=Red; if (VerboseMode) {Print("(WARNING) Not Safe Win Up At "+TimeToStr(Time[i]));}} else {L_Color=Yellow;}
            if (YesterdayCount<=100) 
            {
               DrawWin[i+1] = High[i+1];
               ObjectCreate("CALL"+IntegerToString(Time[i]),OBJ_TREND,0,Time[i+1+expiryCandle],CallStrikePrice(i+expiryCandle),Time[i+1],Open[i]);
               ObjectSetInteger(0,"CALL"+IntegerToString(Time[i]),OBJPROP_COLOR, L_Color);
               ObjectSetInteger(0,"CALL"+IntegerToString(Time[i]),OBJPROP_STYLE, STYLE_SOLID);
               ObjectSetInteger(0,"CALL"+IntegerToString(Time[i]),OBJPROP_WIDTH, 2);
               ObjectSetInteger(0,"CALL"+IntegerToString(Time[i]),OBJPROP_RAY, false);
               ObjectSetInteger(0,"CALL"+IntegerToString(Time[i]),OBJPROP_BACK, true);
               ObjectSetInteger(0,"CALL"+IntegerToString(Time[i]),OBJPROP_HIDDEN,true);
            }
         } else {
            sumLose++;
            bufferMaxLose++;
            if (MaxWinDelayBuffer==0) {
               MaxWinDelayBuffer=ConsecutiveDelayIndex;
               if (bufferMaxWin>MaxWin) {MaxWin=bufferMaxWin; bufferMaxWin=0; MaxWinDate=TimeToStr(Time[i]);} else {bufferMaxWin=0;}
            } else {MaxWinDelayBuffer--;}
            if (MathAbs(Open[i]-CallStrikePrice(i+expiryCandle))<MathAbs(NotSafeIndex*(Open[i+1+expiryCandle]-CallStrikePrice(i+expiryCandle))/100)) {notSafeLoseUp++; L_Color=Red; if (VerboseMode) {Print("(WARNING) Not Safe Lose Up At "+TimeToStr(Time[i]));}} else {L_Color=Yellow;}
            if (YesterdayCount<=100) 
            {
               DrawLose[i+1] = High[i+1];
               ObjectCreate("CALL"+IntegerToString(Time[i]),OBJ_TREND,0,Time[i+1+expiryCandle],CallStrikePrice(i+expiryCandle),Time[i+1],Open[i]);
               ObjectSetInteger(0,"CALL"+IntegerToString(Time[i]),OBJPROP_COLOR, L_Color);
               ObjectSetInteger(0,"CALL"+IntegerToString(Time[i]),OBJPROP_STYLE, STYLE_SOLID);
               ObjectSetInteger(0,"CALL"+IntegerToString(Time[i]),OBJPROP_WIDTH, 2);
               ObjectSetInteger(0,"CALL"+IntegerToString(Time[i]),OBJPROP_RAY, false);
               ObjectSetInteger(0,"CALL"+IntegerToString(Time[i]),OBJPROP_BACK, true);
               ObjectSetInteger(0,"CALL"+IntegerToString(Time[i]),OBJPROP_HIDDEN,true);
            }
         }
         
         isUpTrade=false;
      }
      
      if (isDownTrade && isNewCandle(i) && tmpExpiry==0) 
      {
         if (PutStrikePrice(i+expiryCandle)>Open[i])
         {
            sumWin++;
            bufferMaxWin++;
            if (MaxLoseDelayBuffer==0) {
               MaxLoseDelayBuffer=ConsecutiveDelayIndex;
               if (bufferMaxLose>MaxLose) {MaxLose=bufferMaxLose; bufferMaxLose=0; MaxLoseDate=TimeToStr(Time[i]);} else {bufferMaxLose=0;}
            } else {MaxLoseDelayBuffer--;}
            if (MathAbs(Open[i]-PutStrikePrice(i+expiryCandle))<MathAbs(NotSafeIndex*(Open[i+1+expiryCandle]-PutStrikePrice(i+expiryCandle))/100)) {notSafeWinDown++; L_Color=Red; if (VerboseMode) {Print("(WARNING) Not Safe Win Down At "+TimeToStr(Time[i]));}} else {L_Color=Yellow;}
            if (YesterdayCount<=100) 
            {
               DrawWin[i+1] = Low[i+1];
               ObjectCreate("PUT"+IntegerToString(Time[i]),OBJ_TREND,0,Time[i+1+expiryCandle],PutStrikePrice(i+expiryCandle),Time[i+1],Open[i]);
               ObjectSetInteger(0,"PUT"+IntegerToString(Time[i]),OBJPROP_COLOR, L_Color);
               ObjectSetInteger(0,"PUT"+IntegerToString(Time[i]),OBJPROP_STYLE, STYLE_SOLID);
               ObjectSetInteger(0,"PUT"+IntegerToString(Time[i]),OBJPROP_WIDTH, 2);
               ObjectSetInteger(0,"PUT"+IntegerToString(Time[i]),OBJPROP_RAY, false);
               ObjectSetInteger(0,"PUT"+IntegerToString(Time[i]),OBJPROP_BACK, true);
               ObjectSetInteger(0,"PUT"+IntegerToString(Time[i]),OBJPROP_HIDDEN,true);
            }
         } else {
            sumLose++;
            bufferMaxLose++;
            if (MaxWinDelayBuffer==0) {
               MaxWinDelayBuffer=ConsecutiveDelayIndex;
               if (bufferMaxWin>MaxWin) {MaxWin=bufferMaxWin; bufferMaxWin=0; MaxWinDate=TimeToStr(Time[i]);} else {bufferMaxWin=0;}
            } else {MaxWinDelayBuffer--;}
            if (MathAbs(Open[i]-PutStrikePrice(i+expiryCandle))<MathAbs(NotSafeIndex*(Open[i+1+expiryCandle]-PutStrikePrice(i+expiryCandle))/100)) {notSafeLoseDown++; L_Color=Red; if (VerboseMode) {Print("(WARNING) Not Safe Lose Down At "+TimeToStr(Time[i]));}} else {L_Color=Yellow;}
            if (YesterdayCount<=100) 
            {
               DrawLose[i+1] = Low[i+1];
               ObjectCreate("PUT"+IntegerToString(Time[i]),OBJ_TREND,0,Time[i+1+expiryCandle],PutStrikePrice(i+expiryCandle),Time[i+1],Open[i]);
               ObjectSetInteger(0,"PUT"+IntegerToString(Time[i]),OBJPROP_COLOR, L_Color);
               ObjectSetInteger(0,"PUT"+IntegerToString(Time[i]),OBJPROP_STYLE, STYLE_SOLID);
               ObjectSetInteger(0,"PUT"+IntegerToString(Time[i]),OBJPROP_WIDTH, 2);
               ObjectSetInteger(0,"PUT"+IntegerToString(Time[i]),OBJPROP_RAY, false);
               ObjectSetInteger(0,"PUT"+IntegerToString(Time[i]),OBJPROP_BACK, true);
               ObjectSetInteger(0,"PUT"+IntegerToString(Time[i]),OBJPROP_HIDDEN,true);
            }
         }
         
         isDownTrade=false;
      }
      
      if (tmpExpiry==0 && isNewCandle(i))
      {
         tmpExpiry=expiryCandle;
      }
      
      if (SafeStrikePriceMode) {
      
         if (Low[i]<((Close[i+1])-MathAbs(StrikePriceIndex*(Open[i+1]-Close[i+1])/100)) && isBuySignal(i+1) && isNewCandle(i)) {
            if (ReverseMode) {
               if (YesterdayCount<=100) {CrossDown[i+1] = High[i+1] + Range*0.75;}
               totalTrade++;
               if (i==0 && SoundAlert) {Alert(Period()+"M "+Symbol()+" PUT SIGNAL at "+TimeToStr(Time[0])+", Strike Price="+Open[0]+", Expire="+expiryCandle+" Candle");}
               if (i==0 && EmailAlert) {SendMail(Symbol()+" PUT SIGNAL",Period()+"M "+Symbol()+" PUT SIGNAL at "+TimeToStr(Time[0])+", Strike Price="+Open[0]+", Expire="+expiryCandle+" Candle");}
               if (i==0 && HotKeyTrigger) {if (HotKeyLoopIndex>1){for (int x=1; x<=HotKeyLoopIndex; x++){SellHotkey(KeyIndex); SleepXIndicators(400);}} else {SellHotkey(KeyIndex);}}
               if (i==0 && ConnectIQAPI) {httpGET("http://localhost:8080/put?lot="+PositionSize+"&exp="+expiryConfig+"&pair="+Symbol());};
                  if (ExpiryCounter>=0) {ExpiryCounter++;}
            
                  if (ExpiryCounter>1 && ExpiryCounter<=expiryCandle) {
                     if (PutStrikePrice(i+ExpiryCounter-1)>Open[i]) {winExpiryUpdater(ExpiryCounter-2);} else {loseExpiryUpdater(ExpiryCounter-2);}
                  }
                  
                  if (tmpExpiry>0) {tmpExpiry--; Prep_isDownTrade=true;}
                  if (tmpExpiry==0 && Prep_isDownTrade)
                  {
                     isDownTrade=true;
                     Prep_isDownTrade=false;
                     ExpiryCounter=0;
                  }
            } else {
               if (YesterdayCount<=100) {CrossUp[i+1] = Low[i+1] - Range*0.75;}
               totalTrade++;
               if (i==0 && SoundAlert) {Alert(Period()+"M "+Symbol()+" CALL SIGNAL at "+TimeToStr(Time[0])+", Strike Price="+Open[0]+", Expire="+expiryCandle+" Candle");}
               if (i==0 && EmailAlert) {SendMail(Symbol()+" CALL SIGNAL",Period()+"M "+Symbol()+" CALL SIGNAL at "+TimeToStr(Time[0])+", Strike Price="+Open[0]+", Expire="+expiryCandle+" Candle");}
               if (i==0 && HotKeyTrigger) {if (HotKeyLoopIndex>1){for (x=1; x<=HotKeyLoopIndex; x++){BuyHotkey(KeyIndex); SleepXIndicators(400);}} else {BuyHotkey(KeyIndex);}}
               if (i==0 && ConnectIQAPI) {httpGET("http://localhost:8080/call?lot="+PositionSize+"&exp="+expiryConfig+"&pair="+Symbol());};
                  if (ExpiryCounter>=0) {ExpiryCounter++;}
            
                  if (ExpiryCounter>1 && ExpiryCounter<=expiryCandle) {
                     if (Open[i]>CallStrikePrice(i+ExpiryCounter-1)) {winExpiryUpdater(ExpiryCounter-2);} else {loseExpiryUpdater(ExpiryCounter-2);}
                  }
                  
                  if (tmpExpiry>0) {tmpExpiry--; Prep_isUpTrade=true;}
                  if (tmpExpiry==0 && Prep_isUpTrade)
                  {
                     isUpTrade=true;
                     Prep_isUpTrade=false;
                     ExpiryCounter=0;
                  }
           }
         }
         
         if (High[i]>((Close[i+1])+MathAbs(StrikePriceIndex*(Open[i+1]-Close[i+1])/100)) && isSellSignal(i+1) && isNewCandle(i)) {
            if (ReverseMode) {
               if (YesterdayCount<=100) {CrossUp[i+1] = Low[i+1] - Range*0.75;}
               totalTrade++;
               if (i==0 && SoundAlert) {Alert(Period()+"M "+Symbol()+" CALL SIGNAL at "+TimeToStr(Time[0])+", Strike Price="+Open[0]+", Expire="+expiryCandle+" Candle");}
               if (i==0 && EmailAlert) {SendMail(Symbol()+" CALL SIGNAL",Period()+"M "+Symbol()+" CALL SIGNAL at "+TimeToStr(Time[0])+", Strike Price="+Open[0]+", Expire="+expiryCandle+" Candle");}
               if (i==0 && HotKeyTrigger) {if (HotKeyLoopIndex>1){for (x=1; x<=HotKeyLoopIndex; x++){BuyHotkey(KeyIndex); SleepXIndicators(400);}} else {BuyHotkey(KeyIndex);}}
               if (i==0 && ConnectIQAPI) {httpGET("http://localhost:8080/call?lot="+PositionSize+"&exp="+expiryConfig+"&pair="+Symbol());};
                  if (ExpiryCounter>=0) {ExpiryCounter++;}
            
                  if (ExpiryCounter>1 && ExpiryCounter<=expiryCandle) {
                     if (Open[i]>CallStrikePrice(i+ExpiryCounter-1)) {winExpiryUpdater(ExpiryCounter-2);} else {loseExpiryUpdater(ExpiryCounter-2);}
                  }
                  
                  if (tmpExpiry>0) {tmpExpiry--; Prep_isUpTrade=true;}
                  if (tmpExpiry==0 && Prep_isUpTrade)
                  {
                     isUpTrade=true;
                     Prep_isUpTrade=false;
                     ExpiryCounter=0;
                  }
            } else {
               if (YesterdayCount<=100) {CrossDown[i+1] = High[i+1] + Range*0.75;}
               totalTrade++;
               if (i==0 && SoundAlert) {Alert(Period()+"M "+Symbol()+" PUT SIGNAL at "+TimeToStr(Time[0])+", Strike Price="+Open[0]+", Expire="+expiryCandle+" Candle");}
               if (i==0 && EmailAlert) {SendMail(Symbol()+" PUT SIGNAL",Period()+"M "+Symbol()+" PUT SIGNAL at "+TimeToStr(Time[0])+", Strike Price="+Open[0]+", Expire="+expiryCandle+" Candle");}
               if (i==0 && HotKeyTrigger) {if (HotKeyLoopIndex>1){for (x=1; x<=HotKeyLoopIndex; x++){SellHotkey(KeyIndex); SleepXIndicators(400);}} else {SellHotkey(KeyIndex);}}
               if (i==0 && ConnectIQAPI) {httpGET("http://localhost:8080/put?lot="+PositionSize+"&exp="+expiryConfig+"&pair="+Symbol());};
                  if (ExpiryCounter>=0) {ExpiryCounter++;}
            
                  if (ExpiryCounter>1 && ExpiryCounter<=expiryCandle) {
                     if (PutStrikePrice(i+ExpiryCounter-1)>Open[i]) {winExpiryUpdater(ExpiryCounter-2);} else {loseExpiryUpdater(ExpiryCounter-2);}
                  }
                  
                  if (tmpExpiry>0) {tmpExpiry--; Prep_isDownTrade=true;}
                  if (tmpExpiry==0 && Prep_isDownTrade)
                  {
                     isDownTrade=true;
                     Prep_isDownTrade=false;
                     ExpiryCounter=0;
                  }
            }
         }
         
         if (Prep_isUpTrade && isNewCandle(i)) 
         {
            if (ExpiryCounter>=0 && Prep_isUpTrade) {ExpiryCounter++;}
            
            if (ExpiryCounter>1 && ExpiryCounter<=expiryCandle && Prep_isUpTrade) {
               if (Open[i]>CallStrikePrice(i+ExpiryCounter-1)) {winExpiryUpdater(ExpiryCounter-2);} else {loseExpiryUpdater(ExpiryCounter-2);}
            }
            
            if (tmpExpiry>0 && Prep_isUpTrade) {tmpExpiry--;}
            if (tmpExpiry==0 && Prep_isUpTrade)
            {
               isUpTrade=true;
               Prep_isUpTrade=false;
               ExpiryCounter=0;
            }
         }
         
         if (Prep_isDownTrade && isNewCandle(i)) 
         {
            if (ExpiryCounter>=0 && Prep_isDownTrade) {ExpiryCounter++;}
            
            if (ExpiryCounter>1 && ExpiryCounter<=expiryCandle && Prep_isDownTrade) {
               if (PutStrikePrice(i+ExpiryCounter-1)>Open[i]) {winExpiryUpdater(ExpiryCounter-2);} else {loseExpiryUpdater(ExpiryCounter-2);}
            }
            
            if (tmpExpiry>0 && Prep_isDownTrade) {tmpExpiry--;}
            if (tmpExpiry==0 && Prep_isDownTrade)
            {
               isDownTrade=true;
               Prep_isDownTrade=false;
               ExpiryCounter=0;
            }
         }
      
      } else {
      
         if (Prep_isUpTrade && isNewCandle(i)) 
         {
            if (tmpExpiry==expiryCandle && Prep_isUpTrade)
            {
               if (ReverseMode) {
                  if (isSellSignal(i+1)) {
                     // Let This Be Like This!!!
                     if (YesterdayCount<=100) {CrossUp[i+1] = Low[i+1] - Range*0.75;}
                     totalTrade++;
                     if (i==0 && SoundAlert) {Alert(Period()+"M "+Symbol()+" CALL SIGNAL at "+TimeToStr(Time[0])+", Strike Price="+Open[0]+", Expire="+expiryCandle+" Candle");}
                     if (i==0 && EmailAlert) {SendMail(Symbol()+" CALL SIGNAL",Period()+"M "+Symbol()+" CALL SIGNAL at "+TimeToStr(Time[0])+", Strike Price="+Open[0]+", Expire="+expiryCandle+" Candle");}
                     if (i==0 && HotKeyTrigger) {if (HotKeyLoopIndex>1){for (x=1; x<=HotKeyLoopIndex; x++){BuyHotkey(KeyIndex); SleepXIndicators(400);}} else {BuyHotkey(KeyIndex);}}
                     if (i==0 && ConnectIQAPI) {httpGET("http://localhost:8080/put?lot="+PositionSize+"&exp="+expiryConfig+"&pair="+Symbol());};
                  } else {Prep_isUpTrade=false;}
               } else {
                  if (isBuySignal(i+1)) {
                     if (YesterdayCount<=100) {CrossUp[i+1] = Low[i+1] - Range*0.75;}
                     totalTrade++;
                     if (i==0 && SoundAlert) {Alert(Period()+"M "+Symbol()+" CALL SIGNAL at "+TimeToStr(Time[0])+", Strike Price="+Open[0]+", Expire="+expiryCandle+" Candle");}
                     if (i==0 && EmailAlert) {SendMail(Symbol()+" CALL SIGNAL",Period()+"M "+Symbol()+" CALL SIGNAL at "+TimeToStr(Time[0])+", Strike Price="+Open[0]+", Expire="+expiryCandle+" Candle");}
                     if (i==0 && HotKeyTrigger) {if (HotKeyLoopIndex>1){for (x=1; x<=HotKeyLoopIndex; x++){BuyHotkey(KeyIndex); SleepXIndicators(400);}} else {BuyHotkey(KeyIndex);}}
                     if (i==0 && ConnectIQAPI) {httpGET("http://localhost:8080/call?lot="+PositionSize+"&exp="+expiryConfig+"&pair="+Symbol());};
                  } else {Prep_isUpTrade=false;}
               }
            }
            
            if (ExpiryCounter>=0 && Prep_isUpTrade) {ExpiryCounter++;}
            
            if (ExpiryCounter>1 && ExpiryCounter<=expiryCandle && Prep_isUpTrade) {
               if (Open[i]>CallStrikePrice(i+ExpiryCounter-1)) {winExpiryUpdater(ExpiryCounter-2);} else {loseExpiryUpdater(ExpiryCounter-2);}
            }
            
            if (tmpExpiry>0 && Prep_isUpTrade) {tmpExpiry--;}
            if (tmpExpiry==0 && Prep_isUpTrade)
            {
               isUpTrade=true;
               Prep_isUpTrade=false;
               ExpiryCounter=0;
            }            
         }
         
         if (Prep_isDownTrade && isNewCandle(i)) 
         {
            if (tmpExpiry==expiryCandle && Prep_isDownTrade) 
            {
               if (ReverseMode) {
                  if (isBuySignal(i+1)) {
                     // Let This Be Like This!!!
                     if (YesterdayCount<=100) {CrossDown[i+1] = High[i+1] + Range*0.75;}
                     totalTrade++;
                     if (i==0 && SoundAlert) {Alert(Period()+"M "+Symbol()+" PUT SIGNAL at "+TimeToStr(Time[0])+", Strike Price="+Open[0]+", Expire="+expiryCandle+" Candle");}
                     if (i==0 && EmailAlert) {SendMail(Symbol()+" PUT SIGNAL",Period()+"M "+Symbol()+" PUT SIGNAL at "+TimeToStr(Time[0])+", Strike Price="+Open[0]+", Expire="+expiryCandle+" Candle");}
                     if (i==0 && HotKeyTrigger) {if (HotKeyLoopIndex>1){for (x=1; x<=HotKeyLoopIndex; x++){SellHotkey(KeyIndex); SleepXIndicators(400);}} else {SellHotkey(KeyIndex);}}
                     if (i==0 && ConnectIQAPI) {httpGET("http://localhost:8080/call?lot="+PositionSize+"&exp="+expiryConfig+"&pair="+Symbol());};
                  } else {Prep_isDownTrade=false;}
               } else {
                  if (isSellSignal(i+1)) {
                     if (YesterdayCount<=100) {CrossDown[i+1] = High[i+1] + Range*0.75;}
                     totalTrade++;
                     if (i==0 && SoundAlert) {Alert(Period()+"M "+Symbol()+" PUT SIGNAL at "+TimeToStr(Time[0])+", Strike Price="+Open[0]+", Expire="+expiryCandle+" Candle");}
                     if (i==0 && EmailAlert) {SendMail(Symbol()+" PUT SIGNAL",Period()+"M "+Symbol()+" PUT SIGNAL at "+TimeToStr(Time[0])+", Strike Price="+Open[0]+", Expire="+expiryCandle+" Candle");}
                     if (i==0 && HotKeyTrigger) {if (HotKeyLoopIndex>1){for (x=1; x<=HotKeyLoopIndex; x++){SellHotkey(KeyIndex); SleepXIndicators(400);}} else {SellHotkey(KeyIndex);}}
                     if (i==0 && ConnectIQAPI) {httpGET("http://localhost:8080/put?lot="+PositionSize+"&exp="+expiryConfig+"&pair="+Symbol());};
                  } else {Prep_isDownTrade=false;}
               }
            }
            
            if (ExpiryCounter>=0 && Prep_isDownTrade) {ExpiryCounter++;}
            
            if (ExpiryCounter>1 && ExpiryCounter<=expiryCandle && Prep_isDownTrade) {
               if (PutStrikePrice(i+ExpiryCounter-1)>Open[i]) {winExpiryUpdater(ExpiryCounter-2);} else {loseExpiryUpdater(ExpiryCounter-2);}
            }
            
            if (tmpExpiry>0 && Prep_isDownTrade) {tmpExpiry--;}
            if (tmpExpiry==0 && Prep_isDownTrade)
            {
               isDownTrade=true;
               Prep_isDownTrade=false;
               ExpiryCounter=0;
            }
         }
         
      }
            
      if (isBuySignal(i) && isNewCandle(i)) //make sure isNewCandle is on the last order
      {
         if (ReverseMode)
         {
            if (i==0 && PrepSoundAlert) {Alert("(PREPARE) "+Period()+"M "+Symbol()+" PUT SIGNAL at Next Candle, Wait for CONFIRMATION SIGNAL, Expire="+expiryCandle+" Candle");}
            if (i==0 && PrepEmailAlert) {SendMail("(PREPARE) "+Symbol()+" PUT SIGNAL","(PREPARE) "+Period()+"M "+Symbol()+" PUT SIGNAL at Next Candle, Wait for CONFIRMATION SIGNAL, Expire="+expiryCandle+" Candle");}
            if (SafeStrikePriceMode==false) {Prep_isDownTrade=true;}
         } else {
            if (i==0 && PrepSoundAlert) {Alert("(PREPARE) "+Period()+"M "+Symbol()+" CALL SIGNAL at Next Candle, Wait for CONFIRMATION SIGNAL, Expire="+expiryCandle+" Candle");}
            if (i==0 && PrepEmailAlert) {SendMail("(PREPARE) "+Symbol()+" CALL SIGNAL","(PREPARE) "+Period()+"M "+Symbol()+" CALL SIGNAL at Next Candle, Wait for CONFIRMATION SIGNAL, Expire="+expiryCandle+" Candle");}
            if (SafeStrikePriceMode==false) {Prep_isUpTrade=true;}
         }
      }
      else if (isSellSignal(i) && isNewCandle(i)) //make sure isNewCandle is on the last order
      {
         if (ReverseMode)
         {
            if (i==0 && PrepSoundAlert) {Alert("(PREPARE) "+Period()+"M "+Symbol()+" CALL SIGNAL at Next Candle, Wait for CONFIRMATION SIGNAL, Expire="+expiryCandle+" Candle");}
            if (i==0 && PrepEmailAlert) {SendMail("(PREPARE) "+Symbol()+" CALL SIGNAL","(PREPARE) "+Period()+"M "+Symbol()+" CALL SIGNAL at Next Candle, Wait for CONFIRMATION SIGNAL, Expire="+expiryCandle+" Candle");}
            if (SafeStrikePriceMode==false) {Prep_isUpTrade=true;}
         } else {
            if (i==0 && PrepSoundAlert) {Alert("(PREPARE) "+Period()+"M "+Symbol()+" PUT SIGNAL at Next Candle, Wait for CONFIRMATION SIGNAL, Expire="+expiryCandle+" Candle");}
            if (i==0 && PrepEmailAlert) {SendMail("(PREPARE) "+Symbol()+" PUT SIGNAL","(PREPARE) "+Period()+"M "+Symbol()+" PUT SIGNAL at Next Candle, Wait for CONFIRMATION SIGNAL, Expire="+expiryCandle+" Candle");}
            if (SafeStrikePriceMode==false) {Prep_isDownTrade=true;}
         }
      }
   }

   //+------------------------------------------------------------------+
   //| Display indicator statistic                                      |
   //+------------------------------------------------------------------+
   if (DisplayStatIndicator)
   {
      // Prepare Value
      double winRatio;
      string Qualified;
      color Q_Color;
      string oneDayOnly;
      int totalTradeForRatio;
      if (totalTrade==0) totalTradeForRatio=1; else totalTradeForRatio=totalTrade;
      winRatio = 1.0*(sumWin*100)/totalTradeForRatio;
      if (MinQualifiedWinRate<=winRatio && MaxQualifiedConsLose>=MaxLose)
      {
         Qualified = "Qualified";
         Q_Color = Green;
         Q_Buffer=false;
      } else {
      Qualified = "Not Qualified";
      Q_Color = Red;
      if (Q_Buffer==false && NotQualifiedSignalNotify) {SendMail("(WARNING) Signal NOT QUALIFIED","(WARNING) "+Period()+"M "+Symbol()+" Signal NOT QUALIFIED at "+TimeToStr(Time[0])+" ("+sumWin+"-"+sumLose+"-"+totalTrade+"-"+DoubleToStr(winRatio,2)+"%)"); Q_Buffer=true;}
      }
      
      if (winRatio==0) {Qualified = "Not Valid"; Q_Color = Yellow;}
      if (CalculateOnlyOneDay) {oneDayOnly = "One Day Mode";} else {oneDayOnly = "Global Mode";}
      
   	// Create The object
	   ObjectCreate ("datetitle", OBJ_LABEL, 0, 0, 0);
	   ObjectCreate ("title", OBJ_LABEL, 0, 0, 0);
	   ObjectCreate ("sumTrade", OBJ_LABEL, 0, 0, 0);
	   ObjectCreate ("sumWinLose", OBJ_LABEL, 0, 0, 0);
	   ObjectCreate ("sumNotSafeWin", OBJ_LABEL, 0, 0, 0);
	   ObjectCreate ("sumNotSafeLose", OBJ_LABEL, 0, 0, 0);
	   ObjectCreate ("maxWin", OBJ_LABEL, 0, 0, 0);
	   ObjectCreate ("maxLose", OBJ_LABEL, 0, 0, 0);
	   ObjectCreate ("winRatio", OBJ_LABEL, 0, 0, 0);
	   ObjectCreate ("qualified", OBJ_LABEL, 0, 0, 0);

	   // set the text for the label
	   ObjectSetText ("datetitle","Analysis Date: "+TimeToStr(Time[0], TIME_DATE),8,"Arial", White);
	   ObjectSetText ("title", "Count Mode: "+oneDayOnly,8,"Arial", White);
	   ObjectSetText ("sumTrade", "Total Trade: "+totalTrade,8,"Arial", White);
	   ObjectSetText ("sumWinLose", "Win / Lose: "+sumWin+" / "+sumLose,8,"Arial", White);
	   ObjectSetText ("sumNotSafeWin", "Not Safe Win Up / Down: "+notSafeWinUp+" / "+notSafeWinDown,8,"Arial", White);
	   ObjectSetText ("sumNotSafeLose", "Not Safe Lose Up / Down: "+notSafeLoseUp+" / "+notSafeLoseDown,8,"Arial", White);
	   ObjectSetText ("maxWin", "Consecutive Win: "+MaxWin+" - Date: ("+MaxWinDate+")",8,"Arial", White);
	   ObjectSetText ("maxLose", "Consecutive Lose: "+MaxLose+" - Date: ("+MaxLoseDate+")",8,"Arial", White);
	   ObjectSetText ("winRatio", "Win Ratio: "+DoubleToStr(winRatio,2)+"%",8,"Arial", White);
	   ObjectSetText ("qualified",Qualified,8,"Arial", Q_Color);

	   // set the corner
	   ObjectSet ("datetitle", OBJPROP_CORNER, StatCorner);
	   ObjectSet ("title", OBJPROP_CORNER, StatCorner);
	   ObjectSet ("sumTrade", OBJPROP_CORNER, StatCorner);
	   ObjectSet ("sumWinLose", OBJPROP_CORNER, StatCorner);
	   ObjectSet ("sumNotSafeWin", OBJPROP_CORNER, StatCorner);
	   ObjectSet ("sumNotSafeLose", OBJPROP_CORNER, StatCorner);
	   ObjectSet ("maxWin", OBJPROP_CORNER, StatCorner);
	   ObjectSet ("maxLose", OBJPROP_CORNER, StatCorner);
	   ObjectSet ("winRatio", OBJPROP_CORNER, StatCorner);
	   ObjectSet ("qualified", OBJPROP_CORNER, StatCorner);

	   // set the corner x distance
	   ObjectSet ("datetitle", OBJPROP_XDISTANCE, 10);
	   ObjectSet ("title", OBJPROP_XDISTANCE, 10);
	   ObjectSet ("sumTrade", OBJPROP_XDISTANCE, 10);
	   ObjectSet ("sumWinLose", OBJPROP_XDISTANCE, 10);
	   ObjectSet ("sumNotSafeWin", OBJPROP_XDISTANCE, 10);
	   ObjectSet ("sumNotSafeLose", OBJPROP_XDISTANCE, 10);
	   ObjectSet ("maxWin", OBJPROP_XDISTANCE, 10);
	   ObjectSet ("maxLose", OBJPROP_XDISTANCE, 10);
	   ObjectSet ("winRatio", OBJPROP_XDISTANCE, 10);
	   ObjectSet ("qualified", OBJPROP_XDISTANCE, 10);

	   // set the corner y distance
	   ObjectSet ("datetitle", OBJPROP_YDISTANCE,10);
	   ObjectSet ("title", OBJPROP_YDISTANCE,25);
	   ObjectSet ("sumTrade", OBJPROP_YDISTANCE,40);
	   ObjectSet ("sumWinLose", OBJPROP_YDISTANCE,55);
	   ObjectSet ("sumNotSafeWin", OBJPROP_YDISTANCE,70);
	   ObjectSet ("sumNotSafeLose", OBJPROP_YDISTANCE,85);
	   ObjectSet ("maxWin", OBJPROP_YDISTANCE,100);
	   ObjectSet ("maxLose", OBJPROP_YDISTANCE,115);
	   ObjectSet ("winRatio", OBJPROP_YDISTANCE,130);
	   ObjectSet ("qualified", OBJPROP_YDISTANCE,145);
	  }
	
	//+------------------------------------------------------------------+
   //| Display yesterday indicator statistic                            |
   //+------------------------------------------------------------------+
	if (DisplayYesterdayStat)
	{
	   int CountBuffer;
	   CountBuffer=YesterdayCount;
	   if (CountBuffer>RowPerColoumn) {CountBuffer=RowPerColoumn;}
	   
	   int skipIndex;
	   
	   if (DisplayAdditionalMode==false) {
	   
      	DrawYesterdayRowTitle (1,CountBuffer);
         	
         for (int a = 1; a <= YesterdayCount; a++)
         {
         	if (a==1) {
         	   // Today Vertical Line at 00.00, not available if in One Year Analysis Mode (YesterdayCount>100)
         	   if (YesterdayCount<=100) 
               {
            	   ObjectDelete("TDay");
                  ObjectCreate(0,"TDay",OBJ_VLINE,0,StrToTime(TimeToStr(Time[0], TIME_DATE)),0);
                  ObjectSetInteger(0,"TDay",OBJPROP_COLOR,Purple);
                  ObjectSetInteger(0,"TDay",OBJPROP_STYLE,STYLE_SOLID);
                  ObjectSetInteger(0,"TDay",OBJPROP_WIDTH,3);
                  ObjectSetInteger(0,"TDay",OBJPROP_BACK,true);
                  ObjectSetInteger(0,"TDay",OBJPROP_SELECTABLE,false);
                  ObjectSetInteger(0,"TDay",OBJPROP_HIDDEN,true);
               }
         	}
         	
         	int sumArray[3];
         	color A_Color;
         	datetime yesterdayIndex = TimeCurrent() - 60 * 60 * 24 * a;
         	datetime dayIndex = StrToTime(TimeToStr(yesterdayIndex, TIME_DATE));
         	getStatOnDate(dayIndex,sumArray);
         	int wins = sumArray[0];
         	int lose = sumArray[1];
         	int totals = sumArray[2];
         	if (wins < 10) {string winx="0"+IntegerToString(wins);} else {winx=IntegerToString(wins);}
         	if (lose < 10) {string losx="0"+IntegerToString(lose);} else {losx=IntegerToString(lose);}
         	if (totals < 10) {string totalsx="00"+IntegerToString(totals);} else if ( totals >=10 && totals < 100 ) {totalsx="0"+IntegerToString(totals);} else {totalsx=IntegerToString(totals);}
         	if (totals==0) int totalWR=1; else totalWR=totals;
         	double WR = 1.0*(wins*100)/totalWR;
         	
         	if (WR==0) {A_Color=Yellow;}
            
         	if (WR < 10) {string WRS = "0"+ DoubleToStr(WR,2)+"%";} else if ( WR == 100) {WRS = DoubleToStr(WR,1)+"%";} else  {WRS = DoubleToStr(WR,2)+"%";}
         	
         	if (MinQualifiedWinRate<=WR)
            {
               A_Color = Green;
            } else {
               A_Color = Red;
         	   if (WR!=0 && currentDate!=tickDate && NotQualifiedSignalNotify) {Alert("(WARNING) "+Period()+"M "+Symbol()+" Yesterday Signal NOT QUALIFIED at "+TimeToStr(TimeCurrent() - 60 * 60 * 24, TIME_DATE)+" ("+winx+"-"+losx+"-"+totalsx+"-"+WRS+")"); tickDate=Day();}
            }
         	
         	if (YesterdayCount<=100) 
            {
            	ObjectDelete("VDay"+IntegerToString(a));
            	ObjectCreate(0,"VDay"+IntegerToString(a),OBJ_VLINE,0,dayIndex,0);
               ObjectSetInteger(0,"VDay"+IntegerToString(a),OBJPROP_COLOR,Purple);
               ObjectSetInteger(0,"VDay"+IntegerToString(a),OBJPROP_STYLE,STYLE_SOLID);
               ObjectSetInteger(0,"VDay"+IntegerToString(a),OBJPROP_WIDTH,3);
               ObjectSetInteger(0,"VDay"+IntegerToString(a),OBJPROP_BACK,true);
               ObjectSetInteger(0,"VDay"+IntegerToString(a),OBJPROP_SELECTABLE,false);
               ObjectSetInteger(0,"VDay"+IntegerToString(a),OBJPROP_HIDDEN,true);
            }
         	
         	if (a<=(RowPerColoumn+skipIndex))
         	{
            	if (winx=="00" && losx=="00" && totalsx=="000" && skipNotValidRow) {skipIndex++; continue;}
            	ObjectCreate ("yday"+IntegerToString(a), OBJ_LABEL, 0, 0, 0);
            	ObjectSetText ("yday"+IntegerToString(a),"| "+TimeToStr(yesterdayIndex, TIME_DATE)+"  | "+winx+" | "+losx+" | "+totalsx+" |  "+WRS,8,"Arial", A_Color);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_CORNER, 3);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_XDISTANCE, 10);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_YDISTANCE,5+(CountBuffer*15)-((a-skipIndex)*15));
         	} 
         	else if (a<=((RowPerColoumn*2)+skipIndex))
         	{      	
            	if (winx=="00" && losx=="00" && totalsx=="000" && skipNotValidRow) {skipIndex++; continue;}
            	if (a==(RowPerColoumn+skipIndex)+1) {DrawYesterdayRowTitle(2,CountBuffer);};
            	ObjectCreate ("yday"+IntegerToString(a), OBJ_LABEL, 0, 0, 0);
            	ObjectSetText ("yday"+IntegerToString(a),"| "+TimeToStr(yesterdayIndex, TIME_DATE)+"  | "+winx+" | "+losx+" | "+totalsx+" |  "+WRS,8,"Arial", A_Color);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_CORNER, 3);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_XDISTANCE, 190);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_YDISTANCE,5+(CountBuffer*15)-((a-(RowPerColoumn+skipIndex))*15));
         	}
         	else if (a<=((RowPerColoumn*3)+skipIndex))
         	{      	
            	if (winx=="00" && losx=="00" && totalsx=="000" && skipNotValidRow) {skipIndex++; continue;}
            	if (a==((RowPerColoumn*2)+skipIndex)+1) {DrawYesterdayRowTitle(3,CountBuffer);};
            	ObjectCreate ("yday"+IntegerToString(a), OBJ_LABEL, 0, 0, 0);
            	ObjectSetText ("yday"+IntegerToString(a),"| "+TimeToStr(yesterdayIndex, TIME_DATE)+"  | "+winx+" | "+losx+" | "+totalsx+" |  "+WRS,8,"Arial", A_Color);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_CORNER, 3);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_XDISTANCE, 370);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_YDISTANCE,5+(CountBuffer*15)-((a-((RowPerColoumn*2)+skipIndex))*15));
         	}
         	else if (a<=((RowPerColoumn*4)+skipIndex))
         	{      	
            	if (winx=="00" && losx=="00" && totalsx=="000" && skipNotValidRow) {skipIndex++; continue;}
            	if (a==((RowPerColoumn*3)+skipIndex)+1) {DrawYesterdayRowTitle(4,CountBuffer);};
            	ObjectCreate ("yday"+IntegerToString(a), OBJ_LABEL, 0, 0, 0);
            	ObjectSetText ("yday"+IntegerToString(a),"| "+TimeToStr(yesterdayIndex, TIME_DATE)+"  | "+winx+" | "+losx+" | "+totalsx+" |  "+WRS,8,"Arial", A_Color);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_CORNER, 3);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_XDISTANCE, 550);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_YDISTANCE,5+(CountBuffer*15)-((a-((RowPerColoumn*3)+skipIndex))*15));
         	} else if (a<=((RowPerColoumn*5)+skipIndex))
         	{      	
            	if (winx=="00" && losx=="00" && totalsx=="000" && skipNotValidRow) {skipIndex++; continue;}
            	if (a==((RowPerColoumn*4)+skipIndex)+1) {DrawYesterdayRowTitle(5,CountBuffer);};
            	ObjectCreate ("yday"+IntegerToString(a), OBJ_LABEL, 0, 0, 0);
            	ObjectSetText ("yday"+IntegerToString(a),"| "+TimeToStr(yesterdayIndex, TIME_DATE)+"  | "+winx+" | "+losx+" | "+totalsx+" |  "+WRS,8,"Arial", A_Color);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_CORNER, 3);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_XDISTANCE, 730);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_YDISTANCE,5+(CountBuffer*15)-((a-((RowPerColoumn*4)+skipIndex))*15));
         	} else if (a<=((RowPerColoumn*6)+skipIndex))
         	{      	
            	if (winx=="00" && losx=="00" && totalsx=="000" && skipNotValidRow) {skipIndex++; continue;}
            	if (a==((RowPerColoumn*5)+skipIndex)+1) {DrawYesterdayRowTitle(6,CountBuffer);};
            	ObjectCreate ("yday"+IntegerToString(a), OBJ_LABEL, 0, 0, 0);
            	ObjectSetText ("yday"+IntegerToString(a),"| "+TimeToStr(yesterdayIndex, TIME_DATE)+"  | "+winx+" | "+losx+" | "+totalsx+" |  "+WRS,8,"Arial", A_Color);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_CORNER, 3);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_XDISTANCE, 910);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_YDISTANCE,5+(CountBuffer*15)-((a-((RowPerColoumn*5)+skipIndex))*15));
         	} else if (a<=((RowPerColoumn*7)+skipIndex))
         	{      	
            	if (winx=="00" && losx=="00" && totalsx=="000" && skipNotValidRow) {skipIndex++; continue;}
            	if (a==((RowPerColoumn*6)+skipIndex)+1) {DrawYesterdayRowTitle(7,CountBuffer);};
            	ObjectCreate ("yday"+IntegerToString(a), OBJ_LABEL, 0, 0, 0);
            	ObjectSetText ("yday"+IntegerToString(a),"| "+TimeToStr(yesterdayIndex, TIME_DATE)+"  | "+winx+" | "+losx+" | "+totalsx+" |  "+WRS,8,"Arial", A_Color);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_CORNER, 3);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_XDISTANCE, 1090);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_YDISTANCE,5+(CountBuffer*15)-((a-((RowPerColoumn*6)+skipIndex))*15));
         	} else if (a>((RowPerColoumn*7)+skipIndex)) {break;}
         }
      } else {
         
         DrawAdditionalYesterdayRowTitle (1,CountBuffer);
         	
         for (a = 1; a <= YesterdayCount; a++)
         {
         	if (a==1) {
         	   // Today Vertical Line at 00.00, not available if in One Year Analysis Mode (YesterdayCount>100)
         	   if (YesterdayCount<=100) 
               {
            	   ObjectDelete("TDay");
                  ObjectCreate(0,"TDay",OBJ_VLINE,0,StrToTime(TimeToStr(Time[0], TIME_DATE)),0);
                  ObjectSetInteger(0,"TDay",OBJPROP_COLOR,Purple);
                  ObjectSetInteger(0,"TDay",OBJPROP_STYLE,STYLE_SOLID);
                  ObjectSetInteger(0,"TDay",OBJPROP_WIDTH,3);
                  ObjectSetInteger(0,"TDay",OBJPROP_BACK,true);
                  ObjectSetInteger(0,"TDay",OBJPROP_SELECTABLE,false);
                  ObjectSetInteger(0,"TDay",OBJPROP_HIDDEN,true);
               }
         	}
         	
         	int AdditionalArray[7];
         	color B_Color;
         	yesterdayIndex = TimeCurrent() - 60 * 60 * 24 * a;
         	dayIndex = StrToTime(TimeToStr(yesterdayIndex, TIME_DATE));
         	getAdditionalStatOnDate(dayIndex,AdditionalArray);
         	int Maxwins = AdditionalArray[0];
         	int Maxlose = AdditionalArray[1];
         	int NotSafeWinUps = AdditionalArray[2];
         	int NotSafeWinDowns = AdditionalArray[3];
         	int NotSafeLoseUps = AdditionalArray[4];
         	int NotSafeLoseDowns = AdditionalArray[5];
         	string MaxLoseTimex = TimeToStr(AdditionalArray[6],TIME_MINUTES);
         	int TotalNotSafeWin = NotSafeWinUps+NotSafeWinDowns;
         	int TotalNotSafeLose = NotSafeLoseUps+NotSafeLoseDowns;
         	if (Maxwins < 10) {string Maxwinx="0"+IntegerToString(Maxwins);} else {Maxwinx=IntegerToString(Maxwins);}
         	if (Maxlose < 10) {string Maxlosx="0"+IntegerToString(Maxlose);} else {Maxlosx=IntegerToString(Maxlose);}
         	if (TotalNotSafeWin < 10) {string TotalNotSafeWinx="0"+IntegerToString(TotalNotSafeWin);} else {TotalNotSafeWinx=IntegerToString(TotalNotSafeWin);}
         	if (TotalNotSafeLose < 10) {string TotalNotSafeLosex="0"+IntegerToString(TotalNotSafeLose);} else {TotalNotSafeLosex=IntegerToString(TotalNotSafeLose);}
         	
         	if (MaxQualifiedConsLose>=Maxlose)
            {
               B_Color = Green;
            } else {
               B_Color = Red;
         	}
         	
         	if (YesterdayCount<=100) 
            {
            	ObjectDelete("VDay"+IntegerToString(a));
            	ObjectCreate(0,"VDay"+IntegerToString(a),OBJ_VLINE,0,dayIndex,0);
               ObjectSetInteger(0,"VDay"+IntegerToString(a),OBJPROP_COLOR,Purple);
               ObjectSetInteger(0,"VDay"+IntegerToString(a),OBJPROP_STYLE,STYLE_SOLID);
               ObjectSetInteger(0,"VDay"+IntegerToString(a),OBJPROP_WIDTH,3);
               ObjectSetInteger(0,"VDay"+IntegerToString(a),OBJPROP_BACK,true);
               ObjectSetInteger(0,"VDay"+IntegerToString(a),OBJPROP_SELECTABLE,false);
               ObjectSetInteger(0,"VDay"+IntegerToString(a),OBJPROP_HIDDEN,true);
            }
         	
         	if (a<=(RowPerColoumn+skipIndex))
         	{
            	if (Maxwinx=="00" && Maxlosx=="00" && TotalNotSafeWinx=="00" && TotalNotSafeLosex=="00" && skipNotValidRow) {skipIndex++; continue;}
            	ObjectCreate ("yday"+IntegerToString(a), OBJ_LABEL, 0, 0, 0);
            	ObjectSetText ("yday"+IntegerToString(a),"| "+TimeToStr(yesterdayIndex, TIME_DATE)+" | "+TotalNotSafeWinx+" | "+TotalNotSafeLosex+" | "+Maxwinx+" | "+Maxlosx+" | "+MaxLoseTimex,8,"Arial", B_Color);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_CORNER, 3);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_XDISTANCE, 10);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_YDISTANCE,5+(CountBuffer*15)-((a-skipIndex)*15));
         	} 
         	else if (a<=((RowPerColoumn*2)+skipIndex))
         	{      	
            	if (Maxwinx=="00" && Maxlosx=="00" && TotalNotSafeWinx=="00" && TotalNotSafeLosex=="00" && skipNotValidRow) {skipIndex++; continue;}
            	if (a==(RowPerColoumn+skipIndex)+1) {DrawAdditionalYesterdayRowTitle(2,CountBuffer);};
            	ObjectCreate ("yday"+IntegerToString(a), OBJ_LABEL, 0, 0, 0);
            	ObjectSetText ("yday"+IntegerToString(a),"| "+TimeToStr(yesterdayIndex, TIME_DATE)+" | "+TotalNotSafeWinx+" | "+TotalNotSafeLosex+" | "+Maxwinx+" | "+Maxlosx+" | "+MaxLoseTimex,8,"Arial", B_Color);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_CORNER, 3);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_XDISTANCE, 190);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_YDISTANCE,5+(CountBuffer*15)-((a-(RowPerColoumn+skipIndex))*15));
         	}
         	else if (a<=((RowPerColoumn*3)+skipIndex))
         	{      	
            	if (Maxwinx=="00" && Maxlosx=="00" && TotalNotSafeWinx=="00" && TotalNotSafeLosex=="00" && skipNotValidRow) {skipIndex++; continue;}
            	if (a==((RowPerColoumn*2)+skipIndex)+1) {DrawAdditionalYesterdayRowTitle(3,CountBuffer);};
            	ObjectCreate ("yday"+IntegerToString(a), OBJ_LABEL, 0, 0, 0);
            	ObjectSetText ("yday"+IntegerToString(a),"| "+TimeToStr(yesterdayIndex, TIME_DATE)+" | "+TotalNotSafeWinx+" | "+TotalNotSafeLosex+" | "+Maxwinx+" | "+Maxlosx+" | "+MaxLoseTimex,8,"Arial", B_Color);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_CORNER, 3);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_XDISTANCE, 370);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_YDISTANCE,5+(CountBuffer*15)-((a-((RowPerColoumn*2)+skipIndex))*15));
         	}
         	else if (a<=((RowPerColoumn*4)+skipIndex))
         	{      	
            	if (Maxwinx=="00" && Maxlosx=="00" && TotalNotSafeWinx=="00" && TotalNotSafeLosex=="00" && skipNotValidRow) {skipIndex++; continue;}
            	if (a==((RowPerColoumn*3)+skipIndex)+1) {DrawAdditionalYesterdayRowTitle(4,CountBuffer);};
            	ObjectCreate ("yday"+IntegerToString(a), OBJ_LABEL, 0, 0, 0);
            	ObjectSetText ("yday"+IntegerToString(a),"| "+TimeToStr(yesterdayIndex, TIME_DATE)+" | "+TotalNotSafeWinx+" | "+TotalNotSafeLosex+" | "+Maxwinx+" | "+Maxlosx+" | "+MaxLoseTimex,8,"Arial", B_Color);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_CORNER, 3);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_XDISTANCE, 550);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_YDISTANCE,5+(CountBuffer*15)-((a-((RowPerColoumn*3)+skipIndex))*15));
         	} else if (a<=((RowPerColoumn*5)+skipIndex))
         	{      	
            	if (Maxwinx=="00" && Maxlosx=="00" && TotalNotSafeWinx=="00" && TotalNotSafeLosex=="00" && skipNotValidRow) {skipIndex++; continue;}
            	if (a==((RowPerColoumn*4)+skipIndex)+1) {DrawAdditionalYesterdayRowTitle(5,CountBuffer);};
            	ObjectCreate ("yday"+IntegerToString(a), OBJ_LABEL, 0, 0, 0);
            	ObjectSetText ("yday"+IntegerToString(a),"| "+TimeToStr(yesterdayIndex, TIME_DATE)+" | "+TotalNotSafeWinx+" | "+TotalNotSafeLosex+" | "+Maxwinx+" | "+Maxlosx+" | "+MaxLoseTimex,8,"Arial", B_Color);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_CORNER, 3);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_XDISTANCE, 730);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_YDISTANCE,5+(CountBuffer*15)-((a-((RowPerColoumn*4)+skipIndex))*15));
         	} else if (a<=((RowPerColoumn*6)+skipIndex))
         	{      	
            	if (Maxwinx=="00" && Maxlosx=="00" && TotalNotSafeWinx=="00" && TotalNotSafeLosex=="00" && skipNotValidRow) {skipIndex++; continue;}
            	if (a==((RowPerColoumn*5)+skipIndex)+1) {DrawAdditionalYesterdayRowTitle(6,CountBuffer);};
            	ObjectCreate ("yday"+IntegerToString(a), OBJ_LABEL, 0, 0, 0);
            	ObjectSetText ("yday"+IntegerToString(a),"| "+TimeToStr(yesterdayIndex, TIME_DATE)+" | "+TotalNotSafeWinx+" | "+TotalNotSafeLosex+" | "+Maxwinx+" | "+Maxlosx+" | "+MaxLoseTimex,8,"Arial", B_Color);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_CORNER, 3);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_XDISTANCE, 910);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_YDISTANCE,5+(CountBuffer*15)-((a-((RowPerColoumn*5)+skipIndex))*15));
         	} else if (a<=((RowPerColoumn*7)+skipIndex))
         	{      	
            	if (Maxwinx=="00" && Maxlosx=="00" && TotalNotSafeWinx=="00" && TotalNotSafeLosex=="00" && skipNotValidRow) {skipIndex++; continue;}
            	if (a==((RowPerColoumn*6)+skipIndex)+1) {DrawAdditionalYesterdayRowTitle(7,CountBuffer);};
            	ObjectCreate ("yday"+IntegerToString(a), OBJ_LABEL, 0, 0, 0);
            	ObjectSetText ("yday"+IntegerToString(a),"| "+TimeToStr(yesterdayIndex, TIME_DATE)+" | "+TotalNotSafeWinx+" | "+TotalNotSafeLosex+" | "+Maxwinx+" | "+Maxlosx+" | "+MaxLoseTimex,8,"Arial", B_Color);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_CORNER, 3);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_XDISTANCE, 1090);
            	ObjectSet ("yday"+IntegerToString(a), OBJPROP_YDISTANCE,5+(CountBuffer*15)-((a-((RowPerColoumn*6)+skipIndex))*15));
         	} else if (a>((RowPerColoumn*7)+skipIndex)) {break;}
         }
      
      }
   }

   return(0);
}