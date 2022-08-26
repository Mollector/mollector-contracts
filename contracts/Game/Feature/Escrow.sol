pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../IMollectorCard.sol";

contract Escrow is Pausable, Ownable, IERC721Receiver {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    mapping(address => bool) public operators;

    struct NftDeposit {
        address nftAddress;
        address ownerAddress;
        string ownerAccount;
        uint256 tokenId;
        uint64 depositedAt;
    }

    struct TokenDeposit {
        address tokenAddress;
        address ownerAddress;
        string ownerAccount;
        uint256 amount;
        uint64 depositedAt;
    }

    struct strToken {
        address tokenAddress;
        string ownerAccount;
        uint256 amount;
    }

    struct strNft {
        address nftAddress;
        string ownerAccount;
        uint256 dna;
        uint256 tokenId;
        bool upgradeable;
    }

    //mapping owner address -> infor data
    mapping(address => NftDeposit[]) public nftDeposits;
    mapping(address => TokenDeposit[]) public tokenDeposits;
    mapping(address => uint256) public userDepositedAmount;

    event DepositNftSuccessful(address indexed _nftAddress, uint256 indexed _tokenId, address _owner, string _ownerAccount, uint64 _depositedAt);
    event DepositTokenSuccessful( address indexed _tokenAddress, uint256 _amount, address _owner string _ownerAccount, uint64 _depositedAt );
    event WithdrawNftSuccessful( address indexed _nftAddress, uint256 indexed _tokenId, uint256 _dna, address _owner );
    event WithdrawTokenSuccessful( address indexed _tokenAddress, uint256 _amount, address _owner );

    struct Proof {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    constructor(address _operator) {
        operators[_operator] = true;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        msg.sender.call(data);
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function verifyProof(bytes memory encode, Proof memory _proof)
        internal
        view
        returns (bool)
    {
        bytes32 digest = keccak256(
            abi.encodePacked(getChainID(), address(this), encode)
        );
        address signatory = ecrecover(digest, _proof.v, _proof.r, _proof.s);
        return operators[signatory];
    }

    function setOperator(address _operator, bool _v) external onlyOwner {
        operators[_operator] = _v;
    }

    function getUserCountNftDeposited(address _add) public view returns (uint256) {
        return nftDeposits[_add].length;
    }    

    function getUserCountTokenDeposited(address _add) public view returns (uint256) {
        return tokenDeposits[_add].length;
    }    

    function getTokenDepositOf(
        address owner,
        uint256 limit,
        uint256 from
    )
        public
        view
        returns (
            uint256 total,
            TokenDeposit[] memory tokenDeposited
        )
    {
        total = getUserCountTokenDeposited(owner);
        if (from < total) {
            uint256 n = total - from > limit ? limit : total - from;
            tokenDeposited = new TokenDeposit[](n);
            for (uint256 i = 0; i < n; i++) {
                tokenDeposited[i] = tokenDeposits[owner][i + from];
            }
        }
    }  

    function getNftDepositOf(
        address owner,
        uint256 limit,
        uint256 from
    )
        public
        view
        returns (
            uint256 total,
            NftDeposit[] memory nftDeposited
        )
    {
        total = getUserCountNftDeposited(owner);
        if (from < total) {
            uint256 n = total - from > limit ? limit : total - from;
            nftDeposited = new NftDeposit[](n);
            for (uint256 i = 0; i < n; i++) {
                nftDeposited[i] = nftDeposits[owner][i + from];
            }
        }
    }    

    function depositToken(strToken memory deposit)
        public
        payable
        whenNotPaused
    {
        address _owner = msg.sender;
        strToken memory tokenDeposit = deposit;
        require(tokenDeposit.amount > 0, "Mollector: AMOUNT MUST BE GREATER THAN 0");

        uint256 amount = 0;
        if (tokenDeposit.tokenAddress == address(0)) {
            require(msg.value > 0, "Mollector: Invalid msg.value");
            amount = msg.value;
        } else {
            require(msg.value == 0, "Mollector: Invalid msg.value");
            require(tokenDeposit.amount > 0, "Mollector: AMOUNT MUST BE GREATER THAN 0");
            amount = tokenDeposit.amount;
        }

        _escrowToken(tokenDeposit.ownerAccount, tokenDeposit.tokenAddress, _owner, amount);

        uint256 depositedAmount = userDepositedAmount[_owner];
        userDepositedAmount[_owner] = depositedAmount.add(tokenDeposit.amount);

        emit DepositTokenSuccessful(tokenDeposit.tokenAddress, amount, _owner, tokenDeposit.ownerAccount, uint64(block.timestamp));
    }

    function depositNft(strNft[] memory deposit)
        external
        whenNotPaused
    {
        require(deposit.length > 0, "Mollector: empty deposit");
        address _owner = msg.sender;

        for (uint256 i = 0; i < deposit.length; i++) {    
            strNft memory nftDeposit = deposit[i];    
            require(_owns(nftDeposit.nftAddress, _owner, nftDeposit.tokenId));

            _escrowNft(nftDeposit.ownerAccount, nftDeposit.nftAddress, _owner, nftDeposit.tokenId);

            emit DepositNftSuccessful(nftDeposit.nftAddress, nftDeposit.tokenId, _owner, nftDeposit.ownerAccount, uint64(block.timestamp));

        }
    }

    function withdrawToken(
        strToken[] memory tokenWithdraws,
        Proof[] memory _proofs
    ) external whenNotPaused {
        require(tokenWithdraws.length > 0, "Mollector: empty tokenWithdraws");

        for (uint256 i = 0; i < tokenWithdraws.length; i++) {
            strToken memory tokenWithdraw = tokenWithdraws[i];

            //require(verifyProof(abi.encodePacked(tokenWithdraw.tokenAddress, msg.sender), _proofs[i]), "Mollector: Wrong proof");
            require(
                0 < tokenWithdraw.amount,
                "Mollector: Invalid withdraw amount"
            );

            _transferTokenOut(
                tokenWithdraw.tokenAddress,
                msg.sender,
                tokenWithdraw.amount
            );

            uint256 depositedAmount = userDepositedAmount[msg.sender];
            userDepositedAmount[msg.sender] = depositedAmount.sub(tokenWithdraw.amount);

            emit WithdrawTokenSuccessful(
                tokenWithdraw.tokenAddress,
                tokenWithdraw.amount,
                msg.sender
            );
        }
    }

    function withdrawNft(
        strNft[] memory nftWithdraws,
        Proof[] memory _proofs
    ) external whenNotPaused {
        require(nftWithdraws.length > 0, "Mollector: empty nftWithdraws");

        for (uint256 i = 0; i < nftWithdraws.length; i++) {
            strNft memory nftWithdraw = nftWithdraws[i];

            require(verifyProof(abi.encodePacked(msg.sender, nftWithdraw.nftAddress, nftWithdraw.tokenId, nftWithdraw.dna), _proofs[i]), "Mollector: Wrong proof");

            if(nftWithdraw.upgradeable){
                IMollectorCard mollectorCard = IMollectorCard(nftWithdraw.nftAddress);
                if(mollectorCard.DNAs(nftWithdraw.tokenId) == 0){
                    mollectorCard.spawn(address(this), nftWithdraw.tokenId, nftWithdraw.dna);
                }

                if(mollectorCard.DNAs(nftWithdraw.tokenId) != nftWithdraw.dna){
                    mollectorCard.update(nftWithdraw.tokenId, nftWithdraw.dna);
                }
            }

            _transferNftOut(
                nftWithdraw.nftAddress,
                msg.sender,
                nftWithdraw.tokenId
            );

            emit WithdrawNftSuccessful(
                nftWithdraw.nftAddress,
                nftWithdraw.tokenId,
                nftWithdraw.dna,
                msg.sender
            );
        }
    }

    function _getNftContract(address _nftAddress)
        internal
        pure
        returns (IERC721)
    {
        IERC721 candidateContract = IERC721(_nftAddress);
        // require(candidateContract.implementsERC721());
        return candidateContract;
    }

    function _owns(
        address _nftAddress,
        address _claimant,
        uint256 _tokenId
    ) internal view returns (bool) {
        IERC721 _nftContract = _getNftContract(_nftAddress);
        return (_nftContract.ownerOf(_tokenId) == _claimant);
    }

    function _escrowToken(
        string memory _ownerAccount,
        address _tokenAddress,
        address _owner,
        uint256 _amount
    ) internal {
        if (_tokenAddress == address(0)) {
            require(msg.value == _amount, "INVALID MSG.VALUE");
        } else {
            IERC20(_tokenAddress).safeTransferFrom(
                msg.sender,
                address(this),
                _amount
            );
        }

        tokenDeposits[_owner].push(
            TokenDeposit({
                tokenAddress: _tokenAddress,
                ownerAccount: _ownerAccount,
                ownerAddress: _owner,
                amount: uint128(_amount),
                depositedAt: uint64(block.timestamp)
            })
        );
    }

    function _escrowNft(
        string memory _ownerAccount,
        address _nftAddress,
        address _owner,
        uint256 _tokenId
    ) internal {
        IERC721 _nftContract = _getNftContract(_nftAddress);
        _nftContract.transferFrom(_owner, address(this), _tokenId);

        nftDeposits[_owner].push(
            NftDeposit({
                nftAddress: _nftAddress,
                ownerAccount: _ownerAccount,
                ownerAddress: _owner,
                tokenId: uint128(_tokenId),
                depositedAt: uint64(block.timestamp)
            })
        );
    }

    function _transferNftOut(
        address _nftAddress,
        address _receiver,
        uint256 _tokenId
    ) internal {
        IERC721 _nftContract = _getNftContract(_nftAddress);

        // It will throw if transfer fails
        _nftContract.safeTransferFrom(address(this), _receiver, _tokenId);
    }

    function _transferTokenOut(
        address _tokenAddress,
        address _receiver,
        uint256 _amount
    ) internal {
        if (_tokenAddress == address(0)) {
            payable(_receiver).transfer(_amount);
        } else {
            IERC20(_tokenAddress).transfer(_receiver, _amount);
        }
    }
}
