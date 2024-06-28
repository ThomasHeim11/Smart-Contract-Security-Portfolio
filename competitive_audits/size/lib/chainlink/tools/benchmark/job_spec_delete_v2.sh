#!/usr/local/bin/bash

CONTRACT_ADDRESSES=(
  0x013832098A55c434E33db02D973dC21F3Eb0bfEE
  0x01CA19e7De4C783311B5c9264F9a43B17d765845
  0x020299e78B6785Fad94D8136c90D9C977E21942a
  0x027fd7173074F64832C6db440254F54c9825b064
  0x03d50127593EC4A04ABf9B994166EAfaFbb9B43a
  0x04C032FB6bF0876D87dea0050B0EcaD2Dcadb0b3
  0x0DF459BeA2975cA9E082E80638C3E2C5c76931aF
  0x12a3516567CEa7eC6DEFFf767Afe3bc82086c1F2
  0x1a4abb159Cb515f4B8f047Ba94b29Bf2BcFE584D
  0x1c2522206437fCaD46a91D880ba1aB3c78F03fF4
  0x209b5fAE458D6F25d3a012Ba6Bbb12C5BC4a9CAf
  0x27FF18679198c6De5ef4aa65eC6CF03dB450e7df
  0x2Ad54266A811865258144C5EbB99e3aE82Fc2F8a
  0x2C29Cf1568f583Ff75962f930Fe978d5041769Ac
  0x2b1066B9306f21cAe47dC7dc6693B5d8a5C42DDb
  0x2e2c3FB6Bda479CFFc9a6A45aEae49b35005f14D
  0x33149D6F6441AC87c8770925fBe2d4E175549AD3
  0x365b4486B162ef6Ca6288C46fA76aCD817c410E6
  0x3A7239Ef9371d39E2831ABa11cE68BBAB5906B65
  0x3BD79F1eEC125D5Abeed0e101b5D465eA7F34d73
  0x3C5219346B3f490e0749D95E94552399103f8543
  0x4df480375a5100A312087bB48B875C77975664F2
  0x5FCB63404E66F3a0e6f6e5488C83Bb08B1286290
  0x5e39b0a03F9b6E0Ba63185b9D0a29f4936dBdbe6
  0x60A34BB5a68B3D4288EB7C7e86051a472Aa5a63F
  0x6227f595A569601d3B950B6D0730acdAeaA8670e
  0x632f487362847a26F186fB3D77D1Fcf329BCDa3b
  0x6703d15E628EB3E0eb454A8f35b3e873c6a2Ea81
  0x68000f119ccF91C1Eb1F59F8364C7fDddeBb8eE0
  0x6D0b2d2E0384F6Bfa89c96469a9E99c82EC0c686
  0x6b7906169356d265e98777e1F8B85F445481B63a
  0x7081EfD8CFb94e47E21106023cf18Ac7b8c54387
  0x7419363111C62a627d3772b1018E095E76B63dC7
  0x7569d7f1823D5d0A3A39bB1a9925d5A9DC54D518
  0x75E9C3E84BaE42273EfD7565840e9f2020d5E683
  0x760322004d26AED43cadEbb499a1Fe4f7Cb4A86D
  0x799d8786fb6eAE43AAea6decBbDF5CD9F19D9D95
  0x7D6773974908d645D043A97Eca1A6E63201a8CFb
  0x7eA828A03BBE18643Ca670792b5B916ae36c019a
  0x83C446940923E60a949F01B20dc6be503dafDDa7
  0x83aF768Bbbdf806402038b782c40683036843f2C
  0x88F422e3Fb5b48a286c6cc493C6339d3700f3010
  0x8Bda4a43dB18113C7D79f1C392E87800F72113e5
  0x8E481B53EE070ae164C0ea4d798738bef1e40B81
  0x8F8a372c5d0F4957764478A2a7Db4EEda902CF76
  0x8f0B39e2c605551E4641FB35E497392F20377b52
  0x90543B84004f5F5f376E3c1700685B1d17A8fcfA
  0x983370972Cb6F8BCf594155d87A250C38a598B9B
  0x98597A208CAd30E3dB8eca00e3fa27901E1E5b40
  0x9E9798F9cAB7EF5004506a9205a00b31662e3C3B
  0x9aA33BF0593Df367A2f15c0465Af8929d3B4Fb73
  0xA351F5494F440D6d8c6329B8c5aDE1a501A3e816
  0xA35E7BF72707f25e8DDEf546aF3a01bBC0Ae1774
  0xA8EB42967B5632aFCBA67C5f832C57F82866103F
  0xB15Eac1d7397A737345ae88df1Caa74303a0183A
  0xB1E137278bb030a68Fd3B5009aE22Ef76Fe80D7D
  0xBA8be48B4Aa89D88EfA7145100a23b52e190dEB3
  0xBDFa2A7f2C279886B9E71EdF93E29E7dAa7E0670
  0xC22aB7076bA7f6ff0472bBd45Ee13DD5735B8Fe8
  0xC6c99c5E6EAED676569649d63f2384A611A469a2
  0xC8c41E499F0694F3e13130f917D08183a0C6F4fB
  0xC8c871900C29954E806d9cBd2f4e1493F66deFf4
  0xCC301615292b97aC08eF9C0992d01684ec4DA818
  0xCe3f414050090Ce49Ea00490E20aaAA6754269b8
  0xD2E1B6E34F7841577b44DA1f7f9935Ad0dF589ad
  0xD418767a961BD2954a53Eb906b80AF9257265DB8
  0xD44cAdB18bEDE0e14252D72666eF334b277B923C
  0xDA40d7CA3d5116429f9c10F8B63faf6b29bAf7b4
  0xEF103D1DDBB686C3E4063150D6276dEdC13d0F70
  0xEF2Ed320cf1f44B3F99867329A7a7572CD104186
  0xEb9A196B776b0b05A2cE40E68cE07400DCb6889F
  0xEc403821297666B25c3B5b539Be52CeA75A3B884
  0xF0945d8369eeCf42C5c3ba25E2ACAC8b39F7bFfb
  0xF20d4F32086B3EeFa27779fd1a80Eee575CcD6b8
  0xF2E9f1C923426b88b45481522628864953FF3441
  0xF8eeB0A0f02e3b1faDd6019d8FAFb0F0BF4a869D
  0xF91a3d8567D96a9A250d9Aa1D2c780B6356Ba8ed
  0xFbF455785c7411Dee676E11594190cE25c12B702
  0xa27243e817b557F673250A44120F8c3a0Db27D12
  0xa325E45Cca179a36afAb7FC7B624d8771A77754a
  0xc4BAFEC0a234BC04855103BAE657EF94D2896D80
  0xd07aa8665d7354286e6f5374353400b8ebc58ac9
  0xd57a5E1Ccb1401A964609d274a3e541426772fc5
  0xd95F31939B3B51A9711F9A4744dEdaE0A3a90D03
  0xde52a4FDfbD7776EA935edF80Afa48a65790F0A8
  0xe8263897c5687DBDcC1596B1CCF10462Ba24a9b4
  0xe8663e2dEC005EFc37B1278aC92E1bdD763873D6
  0xeaBb2a446167cda4F0F96921D2d77d267420aB3C
  0xf0381afDf765FC7E714CC5a1066397c588a65838
  0xf3757166A3A0F509E1370d3f42c2b694B386aab0
  0xf4Ac3711A7Aa0197b3e9c02AAf7aEf89BFBEad7A
)

function make_spec() {
  job_spec=`mktemp /tmp/job_spec_XXXXXX`
  if [ $? -ne 0 ]; then
    echo "$0: Can't create temp file, exiting..."
    exit 1
  fi

  function cleanup {
    rm -f "$job_spec"
  }

  # register the cleanup function to be called on the EXIT signal
  # trap cleanup EXIT

  address="${CONTRACT_ADDRESSES[$1]}"
  cat >> $job_spec <<-EOF
blockchainTimeout = "20s"
contractAddress = "${address}"
contractConfigConfirmations = 3
contractConfigTrackerPollInterval = "1m"
contractConfigTrackerSubscribeInterval = "2m"
isBootstrapPeer = true
p2pBootstrapPeers = []
p2pPeerID = "p2p_12D3KooWMk13oppZXmGdRZgaJBFDF6Tc5521YYxKjwkscLSEPrVW"
schemaVersion = 1
type = "offchainreporting"

EOF

  echo $job_spec
}

chainlink admin login --file tools/clroot/apicredentials

number=${#CONTRACT_ADDRESSES[@]}
echo "Adding jobs..."
time {
  for (( i=1; i<$number; i++ )) do
    job_spec=`make_spec $i`
    chainlink jobs create "$job_spec"
  done
}


echo "Deleting jobs..."
time {
  for (( i=1; i<$number; i++ )) do
    chainlink jobs delete $i
  done
}
