pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Escrow is Pausable, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    mapping(address => bool) public acceptDepositTokens;
    mapping(address => bool) public acceptDepositNFTs;
    mapping(address => bool) public operators;

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

    struct TokenWithdraw {
        address tokenAddress;
        uint256 amount;
    }

    struct NftWithdraw {
        address nftAddress;
        uint256 tokenId;
    }

    //mapping owner address -> nft/token -> infor data
    mapping(address => mapping(address => NftDeposit[])) public nftDeposits;
    mapping(address => mapping(address => TokenDeposit[])) public tokenDeposits;
    mapping(address => mapping(address => uint256)) public userCommitedAmount;

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

    struct Proof {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    constructor(address _operator) {
        operators[_operator] = true;
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

    function setAcceptToken(address _depositToken, bool _accept)
        public
        onlyOwner
    {
        acceptDepositTokens[_depositToken] = _accept;
    }

    function setAcceptNft(address _depositNft, bool _accept) public onlyOwner {
        acceptDepositNFTs[_depositNft] = _accept;
    }

    function setOperator(address _operator, bool _v) external onlyOwner {
        operators[_operator] = _v;
    }

    function depositToken(address _tokenAddress, uint256 _amount)
        public
        payable
        whenNotPaused
    {
        address _owner = msg.sender;
        require(
            acceptDepositTokens[_tokenAddress],
            "Mollector: wrong deposit token"
        );
        require(_amount > 0, "Mollector: AMOUNT MUST BE GREATER THAN 0");

        uint256 amount = 0;
        if (_tokenAddress == address(0)) {
            amount = msg.value;
        } else {
            require(msg.value == 0, "Mollector: Invalid msg.value");
            amount = _amount;
        }

        _escrowToken(_tokenAddress, _owner, amount);

        uint256 commitedAmount = userCommitedAmount[_owner][_tokenAddress];
        userCommitedAmount[_owner][_tokenAddress] = commitedAmount.add(_amount);

        emit DepositTokenSuccessful(_tokenAddress, amount, _owner);
    }

    function depositNft(address _nftAddress, uint256 _tokenId)
        external
        whenNotPaused
    {
        address _owner = msg.sender;
        require(acceptDepositNFTs[_nftAddress], "Mollector: wrong deposit NFT");
        require(_owns(_nftAddress, _owner, _tokenId));

        _escrowNft(_nftAddress, _owner, _tokenId);

        emit DepositNftSuccessful(_nftAddress, _tokenId, _owner);
    }

    function withdrawToken(
        TokenWithdraw[] memory tokenWithdraws,
        Proof[] memory _proofs
    ) external whenNotPaused {
        require(tokenWithdraws.length > 0, "Mollector: empty tokenWithdraws");

        for (uint256 i = 0; i < tokenWithdraws.length; i++) {
            TokenWithdraw memory tokenWithdraw = tokenWithdraws[i];

            //require(verifyProof(abi.encodePacked(tokenWithdraw.tokenAddress, msg.sender), _proofs[i]), "Mollector: Wrong proof");
            require(
                acceptDepositTokens[tokenWithdraw.tokenAddress],
                "Mollector: wrong token"
            );
            require(
                0 < tokenWithdraw.amount,
                "Mollector: Invalid withdraw amount"
            );

            _transferTokenOut(
                tokenWithdraw.tokenAddress,
                msg.sender,
                tokenWithdraw.amount
            );

            uint256 commitedAmount = userCommitedAmount[msg.sender][
                tokenWithdraw.tokenAddress
            ];
            userCommitedAmount[msg.sender][
                tokenWithdraw.tokenAddress
            ] = commitedAmount.sub(tokenWithdraw.amount);

            emit WithdrawTokenSuccessful(
                tokenWithdraw.tokenAddress,
                tokenWithdraw.amount,
                msg.sender
            );
        }
    }

    function withdrawNft(
        NftWithdraw[] memory nftWithdraws,
        Proof[] memory _proofs
    ) external whenNotPaused {
        require(nftWithdraws.length > 0, "Mollector: empty nftWithdraws");

        for (uint256 i = 0; i < nftWithdraws.length; i++) {
            NftWithdraw memory nftWithdraw = nftWithdraws[i];

            require(
                acceptDepositNFTs[nftWithdraw.nftAddress],
                "Mollector: wrong NFT"
            );
            //require(verifyProof(abi.encodePacked(nftWithdraw.nftAddress, msg.sender), _proofs[i]), "Mollector: Wrong proof");

            _transferNftOut(
                nftWithdraw.nftAddress,
                msg.sender,
                nftWithdraw.tokenId
            );

            emit WithdrawNftSuccessful(
                nftWithdraw.nftAddress,
                nftWithdraw.tokenId,
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

        tokenDeposits[_tokenAddress][_owner].push(
            TokenDeposit({
                owner: _owner,
                amount: uint128(_amount),
                depositdAt: uint64(block.timestamp)
            })
        );
    }

    function _escrowNft(
        address _nftAddress,
        address _owner,
        uint256 _tokenId
    ) internal {
        IERC721 _nftContract = _getNftContract(_nftAddress);
        _nftContract.transferFrom(_owner, address(this), _tokenId);

        nftDeposits[_nftAddress][_owner].push(
            NftDeposit({
                owner: _owner,
                tokenId: uint128(_tokenId),
                depositdAt: uint64(block.timestamp)
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
