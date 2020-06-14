% Load params file
load('../../paramsFiles/params31May2017.mat');  

% Misc
buffSize     = 200e3;
buffEnd      = 2*buffSize;
buffOfst     = buffSize/2;
sampFreq     = commsParams.sampFreq;
upsampFactor = commsParams.upsampFactor;
modOrder     = commsParams.modOrder;
fdbckInterval  = commsParams.fdbckInterval;
bitsPerSym   = commsParams.bitsPerSym;
chirpLen     = radarParams.chirpLen;
cpiLen       = radarParams.cpiLen;

%
nPackets  = commsParams.nPackets;
nTxCycles = commsParams.nTxCycles;
nNzeSyms  = commsParams.nNzeSyms;
nTrnSyms  = commsParams.nTrnSyms;
nSfxSyms  = commsParams.nSfxSyms;
sfxSyms   = complex(ones(nSfxSyms,1));

% Tunable waveform parameters
qpskGain    = commsParams.qpskGain;
spreadVal   = commsParams.spreadVal;
chirpGain   = radarParams.chirpGain;

% Feedback message variables
nBkEncBits = fdbckMsgCodeBook.nEncdBits;
bkTrnSyms        = fdbckMsgCodeBook.trnSymbols;
bkSpreadIdx      = fdbckMsgCodeBook.spreadIdx;
bkPermSeqEncoder = fdbckMsgCodeBook.permSeqEncoder;
bkPermSeqIntrlvr = fdbckMsgCodeBook.permSeqIntrlvr;
bkTrellisStruct  = fdbckMsgCodeBook.trellisStruct;
nBkModMsgSyms    = (nBkEncBits/bitsPerSym)*(spreadVal/bitsPerSym);
bkModPktSize     = nBkModMsgSyms*upsampFactor;

% Feedforward message variables
nFwdMsgBits = fdfwdMsgCodeBook.nMsgBits;
nFwdEncBits = fdfwdMsgCodeBook.nEncdBits;
fwdTrnSyms        = fdfwdMsgCodeBook.trnSymbols;
fwdSpreadIdx      = fdfwdMsgCodeBook.spreadIdx;
fwdPermSeqEncoder = fdfwdMsgCodeBook.permSeqEncoder;
fwdPermSeqIntrlvr = fdfwdMsgCodeBook.permSeqIntrlvr;
fwdTrellisStruct  = fdfwdMsgCodeBook.trellisStruct;
fwdMsgSize        = nFwdEncBits/nPackets;
nFwdModMsgSyms    = (nFwdEncBits/(nPackets*bitsPerSym))...
    *(spreadVal/bitsPerSym);
fwdModPktSize     = nFwdModMsgSyms*upsampFactor;
