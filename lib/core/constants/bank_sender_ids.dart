/// Verified TRAI-registered SMS sender IDs for Indian banks.
/// Source: TRAI DLT platform official data.
/// Key   = Display name shown to user in the dropdown
/// Value = List of all registered sender ID headers for that bank
const Map<String, List<String>> kBankSenderIds = {
  'State Bank of India': [
    'SBIINB', 'SBIPSG', 'SBIBNK', 'SBIOTP', 'SBITRN',
    'SBIATM', 'SBICMS', 'SBIMUM', 'SBIDEL', 'SBIAHM',
    'SBIHYD', 'SBIKOL', 'SBICHE', 'SBIBHO', 'SBILUC',
    'CBSSBI', 'ATMSBI', 'SBISEC', 'SBIPAY',
  ],
  'Punjab National Bank': [
    'PNBSMS', 'PNBCCD', 'PNBCRD', 'PNBCRM', 'PNBDBD',
    'PNBHRD', 'PNBJNK', 'PNBLKO', 'PNBMKT', 'PNBOTP',
    'PNBRTS', 'PNBTBD',
  ],
  'HDFC Bank': [
    'HDFCBK', 'HDFCBN', 'HDFCAL', 'HDFCBA', 'HDFCCC',
    'HDFCDC', 'HDFCFD', 'HDFCGC', 'HDFCHI', 'HDFCHL',
    'HDFCIT', 'HDFCLI', 'HDFCPL', 'HDFCRD', 'HDFCSD',
    'HDFCSE', 'HDFCUN', 'HDFSET', 'HDFTST',
  ],
  'ICICI Bank': [
    'ICICIB', 'ICICIN', 'ICBANK', 'ICIBNK', 'ICICBK',
    'ICICIH', 'ICICIK', 'ICICIL', 'ICICTC', 'ICIEMP',
    'ICIOTP',
  ],
  'Axis Bank': [
    'AXISBK', 'AXISB', 'AXISHR', 'AXISIN', 'AXISMR',
    'AXISPR', 'AXISSR', 'AXSFI', 'AXSFIN',
  ],
  'Kotak Mahindra Bank': [
    'KOTAKB', 'KOTAKP', 'KBANKT', 'KTKREM',
    '189766', '111888', '111000', '100811',
  ],
  'Bank of Baroda': [
    'BOBBIZ', 'BOBBNK', 'BOBFRM', 'BOBMSG', 'BOBSCF',
    'BOBSMS', 'BOBTRE', 'BOBTXN', 'BOBUPG', 'BOBRAJ',
    'BOBOTP', 'BOBCMS', 'BOBCRM', 'BOBSCE', 'BOBUPI',
  ],
  'Canara Bank': [
    'CANBNK', 'CAANBK', 'CANMNY', 'CANRRB', 'CANRWD',
  ],
  'Union Bank of India': [
    'UBINDB', 'UBINAT', '100026',
  ],
  'IndusInd Bank': [
    'INDUSB', 'INDUSL', 'INDUSO', 'INDUSA',
    '126666', '127777',
  ],
  'Yes Bank': [
    'YESBNK', 'YESBNG',
  ],
  'IDFC First Bank': [
    'IDFCBK', 'IDFCFB', 'IDFCCM', 'IDFCFZ', 'IDFCIT',
    'IDFCTS', 'IDFCZ', 'IDFSIT',
    '111101', '111102', '111103', '111104', '111105',
    '111106', '111107', '111108', '111109',
  ],
  'Federal Bank': [
    'FEDBNK', 'FEDBKM', 'FEDADV', 'FEDOTP', 'FDBOTP', 'FEDFIN',
  ],
  'Bank of India': [
    'BOIIND', 'BOIINT', 'BOIREM', 'BOISAF', 'BOISME',
    'BOIVKG', 'BOILON', 'BOIJGB', 'BOIBAL', 'BOINJG',
  ],
};

/// Flattened reverse map: senderID → bankName
/// Used at runtime to quickly look up which bank an SMS came from.
/// e.g. 'PNBSMS' → 'Punjab National Bank'
/// Flattened reverse map: senderID → bankName
/// Used at runtime to quickly look up which bank an SMS came from.
/// e.g. 'PNBSMS' → 'Punjab National Bank'
final Map<String, String> kSenderIdToBankName = {
  for (final entry in kBankSenderIds.entries)
    for (final senderId in entry.value)
      senderId.toUpperCase(): entry.key, // <-- ADD .toUpperCase() HERE
};
