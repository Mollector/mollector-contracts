const { Contract, walletAddress, txParams, encodeParameters, sleep } = require('./coreFunction')

// Config network, I tested on tomochain testnet. It's same with ethereum
var {
  RPC,
  GAS_LIMIT,
  GAS_PRICE_TX,
  GAS_PRICE_DEPLOY,
  BLOCK_TIME,

  OWNER_ADDRESS,
  PRIVATE_KEY,
  MoleculeToken_Address,
  MollectorMarket_Address,
  MollectorEscrow_Address,
  MollectorUtils_Address,
  MollectorCard_Address,
  MollectorPack_Address,

  MollectorEscrow_Owner
} = require('./config');

var MoleculeToken
var MollectorMarket
var MollectorEscrow
var MollectorUtils
var MollectorCard
var MollectorPack

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

async function deploy_MoleculeToken() {
  if (MoleculeToken_Address) {
    console.log('SKIP: Deploy MoleculeToken')
  }
  else {
    console.log('CALL: Deploy MoleculeToken')
  }

  MoleculeToken = await Contract(
    RPC,
    PRIVATE_KEY,
    GAS_PRICE_DEPLOY,
    GAS_LIMIT,
    MoleculeToken_Address,
    'MoleculeToken'
  )

  if (!MoleculeToken_Address) {
    await sleep(BLOCK_TIME);
  }

  MoleculeToken_Address = MoleculeToken.address
  console.log('DONE: MoleculeToken:', MoleculeToken_Address)

  return MoleculeToken;
}

async function deploy_MollectorMarket() {
  if (MollectorMarket_Address) {
    console.log('SKIP: Deploy MollectorMarket')
  }
  else {
    console.log('CALL: Deploy MollectorMarket')
  }

  MollectorMarket = await Contract(
    RPC,
    PRIVATE_KEY,
    GAS_PRICE_DEPLOY,
    GAS_LIMIT,
    MollectorMarket_Address,
    'MollectorMarket',
    200,
    OWNER_ADDRESS
  )

  if (!MollectorMarket_Address) {
    await sleep(BLOCK_TIME);
  }

  MollectorMarket_Address = MollectorMarket.address
  console.log('DONE: MollectorMarket:', MollectorMarket_Address)

  return MollectorMarket;
}

async function deploy_MollectorEscrow() {
  if (MollectorEscrow_Address) {
    console.log('SKIP: Deploy MollectorEscrow')
  }
  else {
    console.log('CALL: Deploy MollectorEscrow')
  }

  MollectorEscrow = await Contract(
    RPC,
    PRIVATE_KEY,
    GAS_PRICE_DEPLOY,
    GAS_LIMIT,
    MollectorEscrow_Address,
    'MollectorEscrow',
    MollectorEscrow_Owner
  )

  if (!MollectorEscrow_Address) {
    await sleep(BLOCK_TIME);
  }

  MollectorEscrow_Address = MollectorEscrow.address
  console.log('DONE: MollectorEscrow:', MollectorEscrow_Address)

  return MollectorEscrow;
}

async function deploy_MollectorCard() {
  if (MollectorCard_Address) {
    console.log('SKIP: Deploy MollectorCard')
  }
  else {
    console.log('CALL: Deploy MollectorCard')
  }

  MollectorCard = await Contract(
    RPC,
    PRIVATE_KEY,
    GAS_PRICE_DEPLOY,
    GAS_LIMIT,
    MollectorCard_Address,
    'MollectorCard'
  )

  if (!MollectorCard_Address) {
    await sleep(BLOCK_TIME);
  }

  MollectorCard_Address = MollectorCard.address
  console.log('DONE: MollectorCard:', MollectorCard_Address)

  return MollectorCard;
}

async function deploy_MollectorPack() {
  if (MollectorPack_Address) {
    console.log('SKIP: Deploy MollectorPack')
  }
  else {
    console.log('CALL: Deploy MollectorPack')
  }

  MollectorPack = await Contract(
    RPC,
    PRIVATE_KEY,
    GAS_PRICE_DEPLOY,
    GAS_LIMIT,
    MollectorPack_Address,
    'MollectorPack',
    MollectorCard_Address
  )

  if (!MollectorPack_Address) {
    await sleep(BLOCK_TIME);
  }

  MollectorPack_Address = MollectorPack.address
  console.log('DONE: MollectorPack:', MollectorPack_Address)

  return MollectorPack;
}

async function deploy_MollectorUtils() {
  if (MollectorUtils_Address) {
    console.log('SKIP: Deploy MollectorUtils')
  }
  else {
    console.log('CALL: Deploy MollectorUtils')
  }

  MollectorUtils = await Contract(
    RPC,
    PRIVATE_KEY,
    GAS_PRICE_DEPLOY,
    GAS_LIMIT,
    MollectorUtils_Address,
    'MollectorUtils'
  )

  if (!MollectorUtils_Address) {
    await sleep(BLOCK_TIME);
  }

  MollectorUtils_Address = MollectorUtils.address
  console.log('DONE: MollectorUtils:', MollectorUtils_Address)

  return MollectorUtils;
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

async function main() {
  await deploy_MoleculeToken()
  await deploy_MollectorMarket()
  await deploy_MollectorEscrow()
  await deploy_MollectorCard()
  await deploy_MollectorPack()
  await deploy_MollectorUtils()

  console.log({
    MoleculeToken_Address,
    MollectorMarket_Address,
    MollectorEscrow_Address,
    MollectorUtils_Address,
    MollectorCard_Address,
    MollectorPack_Address,
  })
}

main()