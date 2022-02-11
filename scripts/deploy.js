const { Contract, walletAddress, txParams, encodeParameters, sleep } = require('./coreFunction')

// Config network, I tested on tomochain testnet. It's same with ethereum
var {
  RPC,
  GAS_LIMIT,
  GAS_PRICE_TX,
  GAS_PRICE_DEPLOY,
  BLOCK_TIME,

  OWNER_ADDRESS,
  CYBLOC_PACK_OPERATOR_ADDRESS,
  CYBLOC_PACK_SALE_COMMON_OPERATOR_ADDRESS,
  CYBLOC_PACK_SALE_RARE_OPERATOR_ADDRESS,
  CYBLOC_PACK_SALE_EPIC_OPERATOR_ADDRESS,

  PRIVATE_KEY,
  CYBLOC_PACK_OPERATOR_KEY,
  CYBLOC_PACK_SALE_COMMON_OPERATOR_KEY,
  CYBLOC_PACK_SALE_RARE_OPERATOR_KEY,
  CYBLOC_PACK_SALE_EPIC_OPERATOR_KEY,

  CYBLOC_CORE_ADDRESS,
  CYBLOC_GENE_SCIENTIST_ADDRESS,
  CYBLOC_MENTOR_MANAGER_ADDRESS,
  CYBLOC_PACK_ADDRESS,
  CYBLOC_PACK_SALE_COMMON_ADDRESS,
  CYBLOC_PACK_SALE_RARE_ADDRESS,
  CYBLOC_PACK_SALE_EPIC_ADDRESS,
  CYBLOC_UTIL_ADDRESS,

  PACK_TYPE_COMMON,
  PACK_TYPE_RARE,
  PACK_TYPE_EPIC
} = require('./config');
const { generateProofsUnpack, generateProofsBuypack } = require('./generateProof');

var CYBLOC_CORE;
var CYBLOC_GENE_SCIENTIST;
var CYBLOC_MENTOR_MANAGER;
var CYBLOC_PACK;
var CYBLOC_PACK_SALE_COMMON;
var CYBLOC_PACK_SALE_RARE;
var CYBLOC_PACK_SALE_EPIC;
var CYBLOC_UTIL;

console.log('OWNER_ADDRESS:', OWNER_ADDRESS);

async function txp(v = 0, add) {
  return await txParams(
    RPC,
    add || OWNER_ADDRESS,
    GAS_PRICE_TX,
    GAS_LIMIT,
    v
  )
}

async function deploy_CyBlocGeneScientist() {
  if (CYBLOC_GENE_SCIENTIST_ADDRESS) {
    console.log('SKIP: Deploy CyBlocGeneScientist')
  }
  else {
    console.log('CALL: Deploy CyBlocGeneScientist')
  }

  CYBLOC_GENE_SCIENTIST = await Contract(
    RPC, 
    PRIVATE_KEY, 
    GAS_PRICE_DEPLOY, 
    GAS_LIMIT,
    CYBLOC_GENE_SCIENTIST_ADDRESS, 
    'CyBlocGeneScientist'
  )

  if (!CYBLOC_GENE_SCIENTIST_ADDRESS) {
    await sleep(BLOCK_TIME);
  }

  CYBLOC_GENE_SCIENTIST_ADDRESS = CYBLOC_GENE_SCIENTIST.address
  console.log('DONE: CyBlocGeneScientist:', CYBLOC_GENE_SCIENTIST_ADDRESS)

  return CYBLOC_GENE_SCIENTIST;
}

async function deploy_CyBlocCore() {
  if (CYBLOC_CORE_ADDRESS) {
    console.log('SKIP: Deploy CyBlocCore')
  }
  else {
    console.log('CALL: Deploy CyBlocCore')
  }

  CYBLOC_CORE = await Contract(
    RPC, 
    PRIVATE_KEY, 
    GAS_PRICE_DEPLOY, 
    GAS_LIMIT,
    CYBLOC_CORE_ADDRESS, 
    'CyBlocCore', 
    OWNER_ADDRESS, 
    CYBLOC_GENE_SCIENTIST_ADDRESS
  )

  if (!CYBLOC_CORE_ADDRESS) {
    await sleep(BLOCK_TIME);
  }

  CYBLOC_CORE_ADDRESS = CYBLOC_CORE.address
  console.log('DONE: CyBlocCore:', CYBLOC_CORE_ADDRESS)

  return CYBLOC_CORE;
}

async function deploy_CyBlocMentorManager() {
  if (CYBLOC_MENTOR_MANAGER_ADDRESS) {
    console.log('SKIP: Deploy CyBlocMentorManager')
  }
  else {
    console.log('CALL: Deploy CyBlocMentorManager')
  }

  CYBLOC_MENTOR_MANAGER = await Contract(
    RPC, 
    PRIVATE_KEY, 
    GAS_PRICE_DEPLOY, 
    GAS_LIMIT,
    CYBLOC_MENTOR_MANAGER_ADDRESS, 
    'CyBlocMentorManager', 
    OWNER_ADDRESS, 
    CYBLOC_CORE_ADDRESS, 
    OWNER_ADDRESS
  )

  if (!CYBLOC_MENTOR_MANAGER_ADDRESS) {
    await sleep(BLOCK_TIME);
  }

  CYBLOC_MENTOR_MANAGER_ADDRESS = CYBLOC_MENTOR_MANAGER.address
  console.log('DONE: CyBlocMentorManager:', CYBLOC_MENTOR_MANAGER_ADDRESS)

  return CYBLOC_MENTOR_MANAGER;
}

async function deploy_CyBlocPack() {
  if (CYBLOC_PACK_ADDRESS) {
    console.log('SKIP: Deploy CyBlocPack')
  }
  else {
    console.log('CALL: Deploy CyBlocPack')
  }

  CYBLOC_PACK = await Contract(
    RPC, 
    PRIVATE_KEY, 
    GAS_PRICE_DEPLOY, 
    GAS_LIMIT,
    CYBLOC_PACK_ADDRESS, 
    'CyBlocPack', 
    OWNER_ADDRESS, 
    CYBLOC_CORE_ADDRESS
  )
  if (!CYBLOC_PACK_ADDRESS) {
    await sleep(BLOCK_TIME);
  }

  CYBLOC_PACK_ADDRESS = CYBLOC_PACK.address
  
  console.log('DONE: CyBlocPack:', CYBLOC_PACK_ADDRESS)

  return CYBLOC_PACK;
}

async function deploy_CyBlocPackSale_COMMON() {
  if (CYBLOC_PACK_SALE_COMMON_ADDRESS) {
    console.log('SKIP: Deploy CyBlocPackSale_COMMON')
  }
  else {
    console.log('CALL: Deploy CyBlocPackSale_COMMON')
  }


  CYBLOC_PACK_SALE_COMMON = await Contract(
    RPC, 
    PRIVATE_KEY, 
    GAS_PRICE_DEPLOY, 
    GAS_LIMIT,
    CYBLOC_PACK_SALE_COMMON_ADDRESS, 
    'CyBlocPackSale', 
    OWNER_ADDRESS,
    CYBLOC_PACK_ADDRESS, 
    (await CYBLOC_PACK.PACK_COMMON()).toString(), 
    PACK_TYPE_COMMON.PRICE,
    PACK_TYPE_COMMON.TOTAL_PACK,
    PACK_TYPE_COMMON.START,
    PACK_TYPE_COMMON.END,
    PACK_TYPE_COMMON.MAX_PER_USER
  )
  
  if (!CYBLOC_PACK_SALE_COMMON_ADDRESS) {
    await sleep(BLOCK_TIME);
  }

  CYBLOC_PACK_SALE_COMMON_ADDRESS = CYBLOC_PACK_SALE_COMMON.address
  
  console.log('DONE: CyBlocPackSale_COMMON:', CYBLOC_PACK_SALE_COMMON_ADDRESS)

  return CYBLOC_PACK_SALE_COMMON;
}

async function deploy_CyBlocPackSale_RARE() {
  if (CYBLOC_PACK_SALE_RARE_ADDRESS) {
    console.log('SKIP: Deploy CyBlocPackSale_RARE')
  }
  else {
    console.log('CALL: Deploy CyBlocPackSale_RARE')
  }

  CYBLOC_PACK_SALE_RARE = await Contract(
    RPC, 
    PRIVATE_KEY, 
    GAS_PRICE_DEPLOY, 
    GAS_LIMIT,
    CYBLOC_PACK_SALE_RARE_ADDRESS, 
    'CyBlocPackSale', 
    OWNER_ADDRESS,
    CYBLOC_PACK_ADDRESS, 
    (await CYBLOC_PACK.PACK_RARE()).toString(), 
    PACK_TYPE_RARE.PRICE,
    PACK_TYPE_RARE.TOTAL_PACK,
    PACK_TYPE_RARE.START,
    PACK_TYPE_RARE.END,
    PACK_TYPE_RARE.MAX_PER_USER
  )

  if (!CYBLOC_PACK_SALE_RARE_ADDRESS) {
    await sleep(BLOCK_TIME);
  }

  CYBLOC_PACK_SALE_RARE_ADDRESS = CYBLOC_PACK_SALE_RARE.address
  
  console.log('DONE: CyBlocPackSale_RARE:', CYBLOC_PACK_SALE_RARE_ADDRESS)

  return CYBLOC_PACK_SALE_RARE;
}

async function deploy_CyBlocPackSale_EPIC() {
  if (CYBLOC_PACK_SALE_EPIC_ADDRESS) {
    console.log('SKIP: Deploy CyBlocPackSale_EPIC')
  }
  else {
    console.log('CALL: Deploy CyBlocPackSale_EPIC')
  }

  CYBLOC_PACK_SALE_EPIC = await Contract(
    RPC, 
    PRIVATE_KEY, 
    GAS_PRICE_DEPLOY, 
    GAS_LIMIT,
    CYBLOC_PACK_SALE_EPIC_ADDRESS, 
    'CyBlocPackSale', 
    OWNER_ADDRESS,
    CYBLOC_PACK_ADDRESS, 
    (await CYBLOC_PACK.PACK_EPIC()).toString(), 
    PACK_TYPE_EPIC.PRICE,
    PACK_TYPE_EPIC.TOTAL_PACK,
    PACK_TYPE_EPIC.START,
    PACK_TYPE_EPIC.END,
    PACK_TYPE_EPIC.MAX_PER_USER
  )

  if (!CYBLOC_PACK_SALE_EPIC_ADDRESS) {
    await sleep(BLOCK_TIME);
  }

  CYBLOC_PACK_SALE_EPIC_ADDRESS = CYBLOC_PACK_SALE_EPIC.address
  
  console.log('DONE: CyBlocPackSale_EPIC:', CYBLOC_PACK_SALE_EPIC_ADDRESS)

  return CYBLOC_PACK_SALE_EPIC;
}

async function deploy_CyBlocUtil() {
  if (CYBLOC_UTIL_ADDRESS) {
    console.log('SKIP: Deploy CyBlocPackSale_EPIC')
  }
  else {
    console.log('CALL: Deploy CyBlocPackSale_EPIC')
  }

  CYBLOC_UTIL = await Contract(
    RPC, 
    PRIVATE_KEY, 
    GAS_PRICE_DEPLOY, 
    GAS_LIMIT,
    CYBLOC_UTIL_ADDRESS, 
    'CyblocUtil'
  )

  if (!CYBLOC_UTIL_ADDRESS) {
    await sleep(BLOCK_TIME);
  }
  CYBLOC_UTIL_ADDRESS = CYBLOC_UTIL.address
  
  console.log('DONE: CyBlocPackSale_EPIC:', CYBLOC_UTIL_ADDRESS)

  return CYBLOC_UTIL;
}

async function set_SellerForCyBlocPack_COMMON() {
  var type = (await CYBLOC_PACK.PACK_COMMON()).toString()
  var seller = await CYBLOC_PACK.Sellers(type)
  
  if (seller.toLowerCase() != CYBLOC_PACK_SALE_COMMON.address.toLowerCase()) {
    console.log('CALL: Set seller for CyBlocPack COMMON')
    var tx = await CYBLOC_PACK.setSeller(type, CYBLOC_PACK_SALE_COMMON.address, await txParams(
      RPC,
      OWNER_ADDRESS,
      GAS_PRICE_TX,
      GAS_LIMIT
    ))
    await sleep(BLOCK_TIME);
    console.log('DONE: Set seller for CyBlocPack COMMON')
    return tx;
  }
  else {
    console.log('SKIP: Set seller for CyBlocPack COMMON')
  }
}

async function set_SellerForCyBlocPack_RARE() {
  var type = (await CYBLOC_PACK.PACK_RARE()).toString()
  var seller = await CYBLOC_PACK.Sellers(type)
  
  if (seller.toLowerCase() != CYBLOC_PACK_SALE_RARE.address.toLowerCase()) {
    console.log('CALL: Set seller for CyBlocPack RARE')
    var tx = await CYBLOC_PACK.setSeller(type, CYBLOC_PACK_SALE_RARE.address, await txParams(
      RPC,
      OWNER_ADDRESS,
      GAS_PRICE_TX,
      GAS_LIMIT
    ))
    await sleep(BLOCK_TIME);
    console.log('DONE: Set seller for CyBlocPack RARE')
    return tx;
  }
  else {
    console.log('SKIP: Set seller for CyBlocPack RARE')
  }
}

async function set_SellerForCyBlocPack_EPIC() {
  var type = (await CYBLOC_PACK.PACK_EPIC()).toString()
  var seller = await CYBLOC_PACK.Sellers(type)
  
  if (seller.toLowerCase() != CYBLOC_PACK_SALE_EPIC.address.toLowerCase()) {
    console.log('CALL: Set seller for CyBlocPack EPIC')
    var tx = await CYBLOC_PACK.setSeller(type, CYBLOC_PACK_SALE_EPIC.address, await txParams(
      RPC,
      OWNER_ADDRESS,
      GAS_PRICE_TX,
      GAS_LIMIT
    ))
    await sleep(BLOCK_TIME);
    console.log('DONE: Set seller for CyBlocPack EPIC')
    return tx;
  }
  else {
    console.log('SKIP: Set seller for CyBlocPack EPIC')
  }
}

async function set_CyBlocPackIsSpawnerForCyBlocCore() {
  var isSpawner = await CYBLOC_CORE.spawners(CYBLOC_PACK.address)
  
  if (!isSpawner) {
    console.log('CALL: Set CyBlocPack is a spawner of CyBlocCore')
    var tx = await CYBLOC_CORE.setSpawner(CYBLOC_PACK.address, true, await txParams(
      RPC,
      OWNER_ADDRESS,
      GAS_PRICE_TX,
      GAS_LIMIT
    ))
    await sleep(BLOCK_TIME);
    console.log('DONE: Set CyBlocPack is a spawner of CyBlocCore')
    return tx;
  }
  else {
    console.log('SKIP: Set CyBlocPack is a spawner of CyBlocCore')
  }
}

async function set_CyBlocMentorManagerForCyBlocCore() {
  var isMentorManager = await CYBLOC_CORE.mentorManager(CYBLOC_MENTOR_MANAGER.address)
  
  if (!isMentorManager) {
    console.log('CALL: Set CyBlocMentorManager for CyBlocCore')
    var tx = await CYBLOC_CORE.setMentorManager(CYBLOC_MENTOR_MANAGER.address, true, await txParams(
      RPC,
      OWNER_ADDRESS,
      GAS_PRICE_TX,
      GAS_LIMIT
    ))
    await sleep(BLOCK_TIME);
    console.log('DONE: Set CyBlocMentorManager for CyBlocCore')
    return tx;
  }
  else {
    console.log('SKIP: Set CyBlocMentorManager for CyBlocCore')
  }
}

async function set_OperatorForCyBlocPack() {
  var isOperator = await CYBLOC_PACK.operators(CYBLOC_PACK_OPERATOR_ADDRESS)
  
  if (!isOperator) {
    console.log('CALL: Set Operator for CyBlocPack')
    var tx = await CYBLOC_PACK.setOperator(CYBLOC_PACK_OPERATOR_ADDRESS, true, await txParams(
      RPC,
      OWNER_ADDRESS,
      GAS_PRICE_TX,
      GAS_LIMIT
    ))
    await sleep(BLOCK_TIME);
    console.log('DONE: Set Operator for CyBlocPack')
    return tx;
  }
  else {
    console.log('SKIP: Set Operator for CyBlocPack')
  }
}

async function set_OperatorForCyBlocPackSale_COMMON() {
  var isOperator = await CYBLOC_PACK_SALE_COMMON.operators(CYBLOC_PACK_SALE_COMMON_OPERATOR_ADDRESS)
  
  if (!isOperator) {
    console.log('CALL: Set Operator for CyBlocPackSale_COMMON')
    var tx = await CYBLOC_PACK_SALE_COMMON.setOperator(CYBLOC_PACK_SALE_COMMON_OPERATOR_ADDRESS, true, await txParams(
      RPC,
      OWNER_ADDRESS,
      GAS_PRICE_TX,
      GAS_LIMIT
    ))
    await sleep(BLOCK_TIME);
    console.log('DONE: Set Operator for CyBlocPackSale_COMMON')
    return tx;
  }
  else {
    console.log('SKIP: Set Operator for CyBlocPackSale_COMMON')
  }
}

async function set_OperatorForCyBlocPackSale_RARE() {
  var isOperator = await CYBLOC_PACK_SALE_RARE.operators(CYBLOC_PACK_SALE_RARE_OPERATOR_ADDRESS)
  
  if (!isOperator) {
    console.log('CALL: Set Operator for CyBlocPackSale_RARE')
    var tx = await CYBLOC_PACK_SALE_RARE.setOperator(CYBLOC_PACK_SALE_RARE_OPERATOR_ADDRESS, true, await txParams(
      RPC,
      OWNER_ADDRESS,
      GAS_PRICE_TX,
      GAS_LIMIT
    ))
    await sleep(BLOCK_TIME);
    console.log('DONE: Set Operator for CyBlocPackSale_RARE')
    return tx;
  }
  else {
    console.log('SKIP: Set Operator for CyBlocPackSale_RARE')
  }
}

async function set_OperatorForCyBlocPackSale_EPIC() {
  var isOperator = await CYBLOC_PACK_SALE_EPIC.operators(CYBLOC_PACK_SALE_EPIC_OPERATOR_ADDRESS)
  
  if (!isOperator) {
    console.log('CALL: Set Operator for CyBlocPackSale_EPIC')
    var tx = await CYBLOC_PACK_SALE_EPIC.setOperator(CYBLOC_PACK_SALE_EPIC_OPERATOR_ADDRESS, true, await txParams(
      RPC,
      OWNER_ADDRESS,
      GAS_PRICE_TX,
      GAS_LIMIT
    ))
    await sleep(BLOCK_TIME);
    console.log('DONE: Set Operator for CyBlocPackSale_EPIC')
    return tx;
  }
  else {
    console.log('SKIP: Set Operator for CyBlocPackSale_EPIC')
  }
}

async function main() {
  console.log('\n\n------STEP 1: deploy_CyBlocGeneScientist')
  await deploy_CyBlocGeneScientist()

  console.log('\n\n------STEP 2: deploy_CyBlocCore')
  await deploy_CyBlocCore()

  console.log('\n\n------STEP 3: deploy_CyBlocMentorManager')
  await deploy_CyBlocMentorManager()

      // console.log('\n\n------STEP 4: deploy_CyBlocPack')
      // await deploy_CyBlocPack()

      // console.log('\n\n------STEP 5: deploy_CyBlocPackSale_COMMON')
      // await deploy_CyBlocPackSale_COMMON()

      // console.log('\n\n------STEP 6: deploy_CyBlocPackSale_RARE')
      // await deploy_CyBlocPackSale_RARE()

      // console.log('\n\n------STEP 7: deploy_CyBlocPackSale_EPIC')
      // await deploy_CyBlocPackSale_EPIC()

      // console.log('\n\n------STEP 8: set_SellerForCyBlocPack_COMMON')
      // await set_SellerForCyBlocPack_COMMON()

      // console.log('\n\n------STEP 9: set_SellerForCyBlocPack_RARE')
      // await set_SellerForCyBlocPack_RARE()

      // console.log('\n\n------STEP 10: set_SellerForCyBlocPack_EPIC')
      // await set_SellerForCyBlocPack_EPIC()

  console.log('\n\n------STEP 11: set_CyBlocPackIsSpawnerForCyBlocCore')
  await set_CyBlocPackIsSpawnerForCyBlocCore()

  console.log('\n\n------STEP 12: set_CyBlocMentorManagerForCyBlocCore')
  await set_CyBlocMentorManagerForCyBlocCore()

  console.log('\n\n------STEP 13: set_OperatorForCyBlocPack')
  await set_OperatorForCyBlocPack()

      // console.log('\n\n------STEP 14: set_OperatorForCyBlocPackSale_COMMON')
      // await set_OperatorForCyBlocPackSale_COMMON()

      // console.log('\n\n------STEP 15: set_OperatorForCyBlocPackSale_RARE')
      // await set_OperatorForCyBlocPackSale_RARE()

      // console.log('\n\n------STEP 16: set_OperatorForCyBlocPackSale_EPIC')
      // await set_OperatorForCyBlocPackSale_EPIC()

  console.log('\n\n------STEP 17: deploy_CyBlocUtil')
  await deploy_CyBlocUtil()
  
  console.log({
    CYBLOC_CORE_ADDRESS,
    CYBLOC_GENE_SCIENTIST_ADDRESS,
    CYBLOC_MENTOR_MANAGER_ADDRESS,
    CYBLOC_PACK_ADDRESS,
    CYBLOC_PACK_SALE_COMMON_ADDRESS,
    CYBLOC_PACK_SALE_RARE_ADDRESS,
    CYBLOC_PACK_SALE_EPIC_ADDRESS,
    CYBLOC_UTIL_ADDRESS
  })

  console.log({
    CYBLOC_CORE: CYBLOC_CORE.address,
    CYBLOC_CORE____MAX_MENTORING: (await CYBLOC_CORE.MAX_MENTORING()).toString(),
    CYBLOC_CORE____MENTOR_COOLDOWN_BLOCK: (await CYBLOC_CORE.MENTOR_COOLDOWN_BLOCK()).toString(),
    CYBLOC_CORE____OPEN_COOLDOWN_BLOCK: (await CYBLOC_CORE.OPEN_COOLDOWN_BLOCK()).toString(),
    CYBLOC_CORE____baseURI: (await CYBLOC_CORE.baseURI()).toString(),
    CYBLOC_CORE____contractURIPrefix: (await CYBLOC_CORE.contractURIPrefix()).toString(),
    CYBLOC_CORE____geneScientist: (await CYBLOC_CORE.geneScientist()).toString(),
    CYBLOC_CORE____spawners: CYBLOC_PACK.address + ' - ' + (await CYBLOC_CORE.spawners(CYBLOC_PACK.address)).toString(),
    CYBLOC_CORE____mentorManager: CYBLOC_MENTOR_MANAGER.address + ' - ' + (await CYBLOC_CORE.mentorManager(CYBLOC_MENTOR_MANAGER.address)).toString()
  })

  console.log({
    GENE_SCIENTIST: CYBLOC_GENE_SCIENTIST.address,
    GENE_SCIENTIST____GENE_VERSION: (await CYBLOC_GENE_SCIENTIST.GENE_VERSION()).toString(),

    GENE_SCIENTIST____BRONZE: (await CYBLOC_GENE_SCIENTIST.BRONZE()).toString(),
    GENE_SCIENTIST____SILVER: (await CYBLOC_GENE_SCIENTIST.SILVER()).toString(),
    GENE_SCIENTIST____GOLD: (await CYBLOC_GENE_SCIENTIST.GOLD()).toString(),
    GENE_SCIENTIST____PLATINUM: (await CYBLOC_GENE_SCIENTIST.PLATINUM()).toString(),
    GENE_SCIENTIST____LEGENDARY: (await CYBLOC_GENE_SCIENTIST.LEGENDARY()).toString(),

    GENE_SCIENTIST____TRAIT_NONE: (await CYBLOC_GENE_SCIENTIST.TRAIT_NONE()).toString(),
    GENE_SCIENTIST____TRAIT_COMMON: (await CYBLOC_GENE_SCIENTIST.TRAIT_COMMON()).toString(),
    GENE_SCIENTIST____TRAIT_RARE: (await CYBLOC_GENE_SCIENTIST.TRAIT_RARE()).toString(),
    GENE_SCIENTIST____TRAIT_SUPER_RARE: (await CYBLOC_GENE_SCIENTIST.TRAIT_SUPER_RARE()).toString()
  })

  console.log({
    MENTOR_MANAGER: CYBLOC_MENTOR_MANAGER.address,
    MENTOR_MANAGER____mentorFeeToken1: (await CYBLOC_MENTOR_MANAGER.mentorFeeToken1()).toString(),
    MENTOR_MANAGER____mentorFeeToken2: (await CYBLOC_MENTOR_MANAGER.mentorFeeToken2()).toString(),
    MENTOR_MANAGER____mentorFee1: (await CYBLOC_MENTOR_MANAGER.mentorFee1()).toString(),
    MENTOR_MANAGER____mentorFee2: (await CYBLOC_MENTOR_MANAGER.mentorFee2()).toString(),
    MENTOR_MANAGER____feeTo: (await CYBLOC_MENTOR_MANAGER.feeTo()).toString(),
    MENTOR_MANAGER____CyBloc: (await CYBLOC_MENTOR_MANAGER.CyBloc()).toString()
  })
  
  console.log({
    CYBLOC_PACK: CYBLOC_PACK.address,
    CYBLOC_PACK____PACK_COMMON: (await CYBLOC_PACK.PACK_COMMON()).toString(),
    CYBLOC_PACK____PACK_RARE: (await CYBLOC_PACK.PACK_RARE()).toString(),
    CYBLOC_PACK____PACK_EPIC: (await CYBLOC_PACK.PACK_EPIC()).toString(),
    CYBLOC_PACK____NFTContract: (await CYBLOC_PACK.NFTContract()).toString(),
    CYBLOC_PACK____OPERATOR: (await CYBLOC_PACK.operators(CYBLOC_PACK_OPERATOR_ADDRESS)).toString(),

    CYBLOC_PACK____SELLER_COMMON: (await CYBLOC_PACK.Sellers((await CYBLOC_PACK.PACK_COMMON()).toString())).toString(),
    CYBLOC_PACK____SELLER_RARE: (await CYBLOC_PACK.Sellers((await CYBLOC_PACK.PACK_RARE()).toString())).toString(),
    CYBLOC_PACK____SELLER_EPIC: (await CYBLOC_PACK.Sellers((await CYBLOC_PACK.PACK_EPIC()).toString())).toString(),
  })
  
  console.log({
    CYBLOC_PACK_SALE_COMMON: CYBLOC_PACK_SALE_COMMON.address,
    CYBLOC_PACK_SALE_COMMON____CYBLOC_PACK: (await CYBLOC_PACK_SALE_COMMON.CYBLOC_PACK()).toString(),
    CYBLOC_PACK_SALE_COMMON____PACK_TYPE: (await CYBLOC_PACK_SALE_COMMON.PACK_TYPE()).toString(),

    CYBLOC_PACK_SALE_COMMON____PRESALE_START: (await CYBLOC_PACK_SALE_COMMON.PRESALE_START()).toString(),
    CYBLOC_PACK_SALE_COMMON____PRESALE_END: (await CYBLOC_PACK_SALE_COMMON.PRESALE_END()).toString(),

    CYBLOC_PACK_SALE_COMMON____TOTAL_PACK: (await CYBLOC_PACK_SALE_COMMON.TOTAL_PACK()).toString(),
    CYBLOC_PACK_SALE_COMMON____MAX_PER_USER: (await CYBLOC_PACK_SALE_COMMON.MAX_PER_USER()).toString(),
    CYBLOC_PACK_SALE_COMMON____PACK_PRICE: (await CYBLOC_PACK_SALE_COMMON.PACK_PRICE()).toString(),

    CYBLOC_PACK_SALE_COMMON____OPERATOR: (await CYBLOC_PACK_SALE_COMMON.operators(CYBLOC_PACK_SALE_COMMON_OPERATOR_ADDRESS)).toString(),
  })

  console.log({
    CYBLOC_PACK_SALE_RARE: CYBLOC_PACK_SALE_RARE.address,
    CYBLOC_PACK_SALE_RARE____CYBLOC_PACK: (await CYBLOC_PACK_SALE_RARE.CYBLOC_PACK()).toString(),
    CYBLOC_PACK_SALE_RARE____PACK_TYPE: (await CYBLOC_PACK_SALE_RARE.PACK_TYPE()).toString(),

    CYBLOC_PACK_SALE_RARE____PRESALE_START: (await CYBLOC_PACK_SALE_RARE.PRESALE_START()).toString(),
    CYBLOC_PACK_SALE_RARE____PRESALE_END: (await CYBLOC_PACK_SALE_RARE.PRESALE_END()).toString(),

    CYBLOC_PACK_SALE_RARE____TOTAL_PACK: (await CYBLOC_PACK_SALE_RARE.TOTAL_PACK()).toString(),
    CYBLOC_PACK_SALE_RARE____MAX_PER_USER: (await CYBLOC_PACK_SALE_RARE.MAX_PER_USER()).toString(),
    CYBLOC_PACK_SALE_RARE____PACK_PRICE: (await CYBLOC_PACK_SALE_RARE.PACK_PRICE()).toString(),

    CYBLOC_PACK_SALE_RARE____OPERATOR: (await CYBLOC_PACK_SALE_RARE.operators(CYBLOC_PACK_SALE_RARE_OPERATOR_ADDRESS)).toString(),
  })

  console.log({
    CYBLOC_PACK_SALE_EPIC: CYBLOC_PACK_SALE_EPIC.address,
    CYBLOC_PACK_SALE_EPIC____CYBLOC_PACK: (await CYBLOC_PACK_SALE_EPIC.CYBLOC_PACK()).toString(),
    CYBLOC_PACK_SALE_EPIC____PACK_TYPE: (await CYBLOC_PACK_SALE_EPIC.PACK_TYPE()).toString(),

    CYBLOC_PACK_SALE_EPIC____PRESALE_START: (await CYBLOC_PACK_SALE_EPIC.PRESALE_START()).toString(),
    CYBLOC_PACK_SALE_EPIC____PRESALE_END: (await CYBLOC_PACK_SALE_EPIC.PRESALE_END()).toString(),

    CYBLOC_PACK_SALE_EPIC____TOTAL_PACK: (await CYBLOC_PACK_SALE_EPIC.TOTAL_PACK()).toString(),
    CYBLOC_PACK_SALE_EPIC____MAX_PER_USER: (await CYBLOC_PACK_SALE_EPIC.MAX_PER_USER()).toString(),
    CYBLOC_PACK_SALE_EPIC____PACK_PRICE: (await CYBLOC_PACK_SALE_EPIC.PACK_PRICE()).toString(),

    CYBLOC_PACK_SALE_EPIC____OPERATOR: (await CYBLOC_PACK_SALE_EPIC.operators(CYBLOC_PACK_SALE_EPIC_OPERATOR_ADDRESS)).toString(),
  })
}

main()