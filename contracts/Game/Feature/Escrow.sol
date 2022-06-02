pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract Escrow is Pausable, Ownable {
  using SafeERC20 for IERC20;

  mapping(address => bool) public acceptDepositTokens;
  mapping(address => bool) public acceptDepositNFTs;


  struct NftDeposit {
    address owner;
    uint256 tokenId;
    uint64 depositdAt;
  }

  struct TokenDeposit {
    address owner;
    uint256 amount;
    uint64 depositdAt;
  }  
  //mapping owner address -> nft/token -> infor data
  mapping (address => mapping (address => NftDeposit)) public nftDeposits;
  mapping (address => mapping (address => TokenDeposit)) public tokenDeposits;

  event DepositNftSuccessful(
    address indexed _nftAddress,
    uint256 indexed _tokenId,
    address _owner
  );

  event DepositTokenSuccessful(
    address indexed _tokenAddress,
    uint256 _amount,
    address _owner
  );  

  event WithdrawNftSuccessful(
    address indexed _nftAddress,
    uint256 indexed _tokenId,
    address _owner
  );

  event WithdrawTokenSuccessful(
    address indexed _tokenAddress,
    uint256 _amount,
    address _owner
  );  


  function setAcceptToken(address _depositToken, bool _accept) public onlyOwner {
    acceptDepositTokens[_depositToken] = _accept;
  }

  function setAcceptNft(address _depositNft, bool _accept) public onlyOwner {
    acceptDepositNFTs[_depositNft] = _accept;
  }

  function depositToken(
    address _tokenAddress,
    uint256 _amount
  )
    public
    payable
    whenNotPaused
  {
    address _owner = msg.sender;
    require(acceptDepositTokens[_tokenAddress], 'Mollector: wrong deposit token'); 
    require(_amount > 0, "Mollector: AMOUNT MUST BE GREATER THAN 0");

    uint256 amount = 0;
    if (_tokenAddress == address(0)) {
      amount = msg.value;
    } else {
      require(msg.value == 0, "Mollector: Invalid msg.value");
      amount = _amount;
    }   

    _escrowToken(_tokenAddress, _owner, amount);

    emit DepositTokenSuccessful(
      _tokenAddress,
      amount,
      _owner
    );
  }

  function depositNft(
    address _nftAddress,
    uint256 _tokenId
  )
    external
    whenNotPaused
  {
    address _owner = msg.sender;
    require(acceptDepositNFTs[_nftAddress], 'Mollector: wrong deposit NFT'); 
    require(_owns(_nftAddress, _owner, _tokenId));  

    _escrowNft(_nftAddress, _owner, _tokenId);

    emit DepositNftSuccessful(
      _nftAddress,
      _tokenId,
      _owner
    );
  }  

  function withdrawToken(
    address _tokenAddress,
    uint256 _amount
  )
    external
    whenNotPaused
  {
    //Todo: verifyProof
    require(acceptDepositTokens[_tokenAddress], 'Mollector: wrong token'); 
    require(0 < _amount, "Mollector: Invalid withdraw amount");
    TokenDeposit storage _tokenDeposit = tokenDeposits[_tokenAddress][msg.sender];
      
    require(0 < _tokenDeposit.amount, "Mollector: no deposited amount");
    require(_amount <= _tokenDeposit.amount, "Mollector: Wrong amount");

    _transferTokenOut(_tokenAddress, msg.sender, _amount);

    delete tokenDeposits[_tokenAddress][msg.sender];
    emit WithdrawTokenSuccessful(
      _tokenAddress,
      _amount,
      msg.sender
    );
  }  

  function withdrawNft(
    address _nftAddress,
    uint256 _tokenId
  )
    external
    whenNotPaused
  {
    //Todo: verifyProof
    require(acceptDepositNFTs[_nftAddress], 'Mollector: wrong NFT'); 

    NftDeposit storage _nftDeposits = nftDeposits[_nftAddress][msg.sender];
      
    require(0 <= _nftDeposits.tokenId, "Mollector: no deposited token");

    _transferNftOut(_nftAddress, msg.sender, _tokenId);

    delete nftDeposits[_nftAddress][msg.sender];
    emit WithdrawNftSuccessful(
      _nftAddress,
      _tokenId,
      msg.sender
    );
  }    

  function _getNftContract(address _nftAddress) internal pure returns (IERC721) {
    IERC721 candidateContract = IERC721(_nftAddress);
    // require(candidateContract.implementsERC721());
    return candidateContract;
  }

  function _owns(address _nftAddress, address _claimant, uint256 _tokenId) internal view returns (bool) {
    IERC721 _nftContract = _getNftContract(_nftAddress);
    return (_nftContract.ownerOf(_tokenId) == _claimant);
  }

  function _escrowToken(address _tokenAddress, address _owner, uint256 _amount) internal {
      if (_tokenAddress == address(0)) {
        require(msg.value == _amount, "INVALID MSG.VALUE");
      } else {
        IERC20(_tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
      } 

    TokenDeposit memory _tokenDeposit = TokenDeposit(
      _owner,
      uint128(_amount),
      uint64(block.timestamp)
    );

    tokenDeposits[_tokenAddress][_owner] = _tokenDeposit;      
  }

  function _escrowNft(address _nftAddress, address _owner, uint256 _tokenId) internal {
    IERC721 _nftContract = _getNftContract(_nftAddress);
    _nftContract.transferFrom(_owner, address(this), _tokenId);

    NftDeposit memory _nftDeposit = NftDeposit(
      _owner,
      uint128(_tokenId),
      uint64(block.timestamp)
    );

    nftDeposits[_nftAddress][_owner] = _nftDeposit;      
  }

  function _transferNftOut(address _nftAddress, address _receiver, uint256 _tokenId) internal {
    IERC721 _nftContract = _getNftContract(_nftAddress);

    // It will throw if transfer fails
    _nftContract.safeTransferFrom(address(this), _receiver, _tokenId);
  }

  function _transferTokenOut(address _tokenAddress, address _receiver, uint256 _amount) internal {
    if (_tokenAddress == address(0)) {
        payable(_receiver).transfer(_amount);
    } else {
        IERC20(_tokenAddress).transfer(_receiver, _amount);
    }
  }  

}
