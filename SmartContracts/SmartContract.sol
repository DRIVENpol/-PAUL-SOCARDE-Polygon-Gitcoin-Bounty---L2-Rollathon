//SPDX-License-Identifier: MIT

// Imports
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./NFT-reward-creators.sol";

pragma solidity ^0.8.13;

contract MainFactory is Ownable {

    uint256 public profileCount;
    NftScCreators public nftRewardCreators;


    struct Profile {
        address creator;
        address factory;
    }

    Profile[] public profiles;

    mapping (address => address) public addressToProfile;
    mapping (address => uint256) public isCreator; // 1 - if the address is a creator
    mapping (address => uint256) public isMinter;

    event NewProfile(
        address creator,
        address factory,
        string profilePicture,
        string category,
        string usenrame
    );

    constructor(NftScCreators _nftRewardCreators) {
       nftRewardCreators = _nftRewardCreators;
    }

    modifier onlyMinter() {
        require(isMinter[msg.sender] == 1);
        _;
    }

    function createProfile(string memory _category, string memory _profilePic, string memory _username) public {
        address newProfile = address(new userProfile(
            msg.sender,
            address(this),
            _profilePic,
            _category,
            _username
        ));

        addressToProfile[msg.sender] = newProfile;

        profiles.push(Profile(
            msg.sender,
            address(this)
            ));

        isMinter[newProfile] = 1;

        emit NewProfile(msg.sender, address(this), _profilePic, _category, _username);
    }

    function mintNftForCreator(address _to, uint256 _option) external onlyMinter() {
       nftRewardCreators.mintNft(_to, _option);
    }

    function setNftRewardCreators(NftScCreators _newNft) public onlyOwner() {
        nftRewardCreators = _newNft;
    }

    // Getters
    function checkCreator(address _who) public view returns(uint256) {
        return isCreator[_who];
    }

}




// USER'S PROFILE - SMART CONTRACT ============================================================





contract userProfile {

// Variables
    NftSc public myNftCollection;

    MainFactory public factory;

    string public profilePicture;
    string public category;

    uint256 public noVideos;
    uint256 public claps;
    uint256 public ethDonations;
    uint256 public nftExist;

    address public creator;

    string public username;
    uint256 public usernameExist = 1; // 1 - don't exist; 2 - exist

    mapping (address => string) public usernameOfCreator;
    mapping (address => mapping (uint256 => uint256)) public donationToCategoryToAddress;
    mapping (address => address) public theNftCollection;

// Video struct
    struct Video {
        uint256 id;
        bytes32 title;
        uint256 videoClaps;
        uint256 totalDonations;
        string description;
        string ipfsLink;
        string author;
    }

// String of videos
    Video[] public videos;

// Events
event CreatedVideo(uint256 id,
        bytes32 title,
        uint256 videoClaps,
        uint256 totalDonations,
        string description,
        string ipfsLink,
        string author);

event Donate(address who, uint256 _id, uint256 _amount);
event Clap(address who, uint256 _id);

// Constructor
constructor( address _creator, address _factory, string memory _profilePicture, string memory _category, string memory _username) {
    creator = _creator;
    factory = MainFactory(_factory);
    profilePicture = _profilePicture;
    category = _category;
    setUsername(_username);
}

// Modifier
modifier onlyCreator {
    require(msg.sender==creator, "You are not the creator!");
    _;
}

// Functions
function uploadVideo(bytes32 _title, string memory _description, string memory _ipfsLink) public onlyCreator {
    uint256 _id = videos.length;
    string memory _author;
    
    if(usernameExist ==2) {
        _author = usernameOfCreator[msg.sender];
    } else {
        _author = Strings.toHexString(uint256(uint160(msg.sender)), 20);
    }

    noVideos++;

    Video memory newVideo = Video(_id, _title, 0, 0, _description, _ipfsLink, _author);
    videos.push(newVideo);

    emit CreatedVideo(_id, _title, 0, 0, _description, _ipfsLink, _author);
}

// Create the NFT collection for people who donated
function createNftCollection(
string memory uri1, string memory uri2,
string memory uri3) public onlyCreator {

require(bytes(uri1).length != 0 && 
bytes(uri2).length != 0 &&
bytes(uri3).length != 0,
"There are empty arguments!");

require(nftExist == 0, "You already created a collection!");

nftExist = 1;

address newNftCollection = address(new NftSc(uri1, uri2,
 uri3, address(this)));

theNftCollection[address(this)] = newNftCollection;
myNftCollection = NftSc(newNftCollection);

}

// Set an username. This action can be called only once
function setUsername(string memory _username) private {
    require(usernameExist == 1);
    usernameOfCreator[msg.sender] = _username;
    usernameExist = 2;
}

function withdrawContributions() public onlyCreator {
    payable(creator).transfer(address(this).balance);
}

function clap(uint256 _videoId) public payable {
    require(_videoId <= videos.length, "Video don't exist!");
    require(msg.sender != creator, "Don't clap on your videos!");
    require(msg.value == 1 ether);
    videos[_videoId].videoClaps++;
    claps++;

    if(claps == 100) {
        factory.mintNftForCreator(creator, 1);
    }

    if(claps == 1000) {
           factory.mintNftForCreator(creator, 1);
    }

    if (claps == 5000) {
          factory.mintNftForCreator(creator, 1);
    }
    

    emit Clap(msg.sender, _videoId);
}

function donateEtherToVideo(uint256 _videoId, uint256 _amount) public payable {
    require(_videoId <= videos.length, "Video don't exist!");
    require(msg.value == _amount);
    uint256 option;

    if(msg.value < 1000 ether) {
        if(msg.value < 500 ether) {
            option = 1;
        } else {
            option = 2;
        }
    } else {
        option = 3;
    }
    
    donationToCategoryToAddress[msg.sender][option]++;

    if(nftExist == 1){
        myNftCollection.mintNft(msg.sender, option);
    }

    videos[_videoId].totalDonations++;

    emit Donate(msg.sender, _videoId, _amount);
  }

receive() external payable {}

}




// NFT FOR USERS - SMART CONTRACT ============================================================





contract NftSc is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // URIS
    string public uri100Matic;
    string public uri250Matic;
    string public uri500Matic;

    address public minter;

    constructor(
        string memory _uri100Matic,
        string memory _uri250Matic,
        string memory _uri500Matic,
        address _minter
    ) ERC721("NFT REWARD FOR USERS", "NRFU") {
        uri100Matic = _uri100Matic;
        uri250Matic = _uri250Matic;
        uri500Matic = _uri500Matic;
        minter = _minter;
    }

    modifier onlyMinter {
        require(msg.sender == minter, "You are not the minter!");
        _;
    }

    function mintNft(address receiver, uint256 _option) external onlyMinter returns (uint256) {
        _tokenIds.increment();
            string memory tokenURI;
        if(_option < 3) {
            if(_option == 2) {
                tokenURI = uri250Matic;
            } else {
                tokenURI = uri100Matic;
            }
        } else {
            tokenURI = uri500Matic;
        }

        uint256 newNftTokenId = _tokenIds.current();
        _mint(receiver, newNftTokenId);
        _setTokenURI(newNftTokenId, tokenURI);

        return newNftTokenId;
    }
}
