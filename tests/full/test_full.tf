terraform {
  required_providers {
    test = {
      source = "terraform.io/builtin/test"
    }

    aci = {
      source  = "netascode/aci"
      version = ">=0.2.0"
    }
  }
}

resource "aci_rest" "fvTenant" {
  dn         = "uni/tn-TF"
  class_name = "fvTenant"
}

resource "aci_rest" "l3extOut" {
  dn         = "${aci_rest.fvTenant.id}/out-L3OUT1"
  class_name = "l3extOut"
}

resource "aci_rest" "l3extLNodeP" {
  dn         = "${aci_rest.l3extOut.id}/lnodep-NP1"
  class_name = "l3extLNodeP"
}

module "main" {
  source = "../.."

  tenant                      = aci_rest.fvTenant.content.name
  l3out                       = aci_rest.l3extOut.content.name
  node_profile                = aci_rest.l3extLNodeP.content.name
  name                        = "IP1"
  bfd_policy                  = "BFD1"
  ospf_interface_profile_name = "OSPFP1"
  ospf_authentication_key     = "12345678"
  ospf_authentication_key_id  = 2
  ospf_authentication_type    = "md5"
  ospf_interface_policy       = "OSPF1"
  interfaces = [{
    description = "Interface 1"
    type        = "vpc"
    svi         = true
    vlan        = 5
    mac         = "12:34:56:78:90:AB"
    mtu         = "1500"
    node_id     = 201
    node2_id    = 202
    pod_id      = 2
    channel     = "VPC1"
    ip_a        = "1.1.1.2/24"
    ip_b        = "1.1.1.3/24"
    ip_shared   = "1.1.1.1/24"
    bgp_peers = [{
      ip          = "1.1.1.10"
      description = "BGP Peer"
      bfd         = true
      ttl         = 10
      weight      = 100
      password    = "PASSWORD"
      remote_as   = "12345"
    }]
  }]
}

data "aci_rest" "l3extLIfP" {
  dn = module.main.dn

  depends_on = [module.main]
}

resource "test_assertions" "l3extLIfP" {
  component = "l3extLIfP"

  equal "name" {
    description = "name"
    got         = data.aci_rest.l3extLIfP.content.name
    want        = module.main.name
  }
}

data "aci_rest" "ospfIfP" {
  dn = "${data.aci_rest.l3extLIfP.id}/ospfIfP"

  depends_on = [module.main]
}

resource "test_assertions" "ospfIfP" {
  component = "ospfIfP"

  equal "name" {
    description = "name"
    got         = data.aci_rest.ospfIfP.content.name
    want        = "OSPFP1"
  }

  equal "authKeyId" {
    description = "authKeyId"
    got         = data.aci_rest.ospfIfP.content.authKeyId
    want        = "2"
  }

  equal "authType" {
    description = "authType"
    got         = data.aci_rest.ospfIfP.content.authType
    want        = "md5"
  }
}

data "aci_rest" "ospfRsIfPol" {
  dn = "${data.aci_rest.ospfIfP.id}/rsIfPol"

  depends_on = [module.main]
}

resource "test_assertions" "ospfRsIfPol" {
  component = "ospfRsIfPol"

  equal "tnOspfIfPolName" {
    description = "tnOspfIfPolName"
    got         = data.aci_rest.ospfRsIfPol.content.tnOspfIfPolName
    want        = "OSPF1"
  }
}

data "aci_rest" "bfdIfP" {
  dn = "${data.aci_rest.l3extLIfP.id}/bfdIfP"

  depends_on = [module.main]
}

resource "test_assertions" "bfdIfP" {
  component = "bfdIfP"

  equal "type" {
    description = "type"
    got         = data.aci_rest.bfdIfP.content.type
    want        = "none"
  }
}

data "aci_rest" "bfdRsIfPol" {
  dn = "${data.aci_rest.bfdIfP.id}/rsIfPol"

  depends_on = [module.main]
}

resource "test_assertions" "bfdRsIfPol" {
  component = "bfdRsIfPol"

  equal "tnBfdIfPolName" {
    description = "tnBfdIfPolName"
    got         = data.aci_rest.bfdRsIfPol.content.tnBfdIfPolName
    want        = "BFD1"
  }
}

data "aci_rest" "l3extRsPathL3OutAtt" {
  dn = "${data.aci_rest.l3extLIfP.id}/rspathL3OutAtt-[topology/pod-2/protpaths-201-202/pathep-[VPC1]]"

  depends_on = [module.main]
}

resource "test_assertions" "l3extRsPathL3OutAtt" {
  component = "l3extRsPathL3OutAtt"

  equal "addr" {
    description = "addr"
    got         = data.aci_rest.l3extRsPathL3OutAtt.content.addr
    want        = "0.0.0.0"
  }

  equal "autostate" {
    description = "autostate"
    got         = data.aci_rest.l3extRsPathL3OutAtt.content.autostate
    want        = "disabled"
  }

  equal "descr" {
    description = "descr"
    got         = data.aci_rest.l3extRsPathL3OutAtt.content.descr
    want        = "Interface 1"
  }

  equal "encapScope" {
    description = "encapScope"
    got         = data.aci_rest.l3extRsPathL3OutAtt.content.encapScope
    want        = "local"
  }

  equal "ifInstT" {
    description = "ifInstT"
    got         = data.aci_rest.l3extRsPathL3OutAtt.content.ifInstT
    want        = "ext-svi"
  }

  equal "encap" {
    description = "encap"
    got         = data.aci_rest.l3extRsPathL3OutAtt.content.encap
    want        = "vlan-5"
  }

  equal "ipv6Dad" {
    description = "ipv6Dad"
    got         = data.aci_rest.l3extRsPathL3OutAtt.content.ipv6Dad
    want        = "enabled"
  }

  equal "llAddr" {
    description = "llAddr"
    got         = data.aci_rest.l3extRsPathL3OutAtt.content.llAddr
    want        = "::"
  }

  equal "mac" {
    description = "mac"
    got         = data.aci_rest.l3extRsPathL3OutAtt.content.mac
    want        = "12:34:56:78:90:AB"
  }

  equal "mode" {
    description = "mode"
    got         = data.aci_rest.l3extRsPathL3OutAtt.content.mode
    want        = "regular"
  }

  equal "mtu" {
    description = "mtu"
    got         = data.aci_rest.l3extRsPathL3OutAtt.content.mtu
    want        = "1500"
  }

  equal "tDn" {
    description = "tDn"
    got         = data.aci_rest.l3extRsPathL3OutAtt.content.tDn
    want        = "topology/pod-2/protpaths-201-202/pathep-[VPC1]"
  }
}

data "aci_rest" "l3extMember_A" {
  dn = "${data.aci_rest.l3extRsPathL3OutAtt.id}/mem-A"

  depends_on = [module.main]
}

resource "test_assertions" "l3extMember_A" {
  component = "l3extMember_A"

  equal "addr" {
    description = "addr"
    got         = data.aci_rest.l3extMember_A.content.addr
    want        = "1.1.1.2/24"
  }

  equal "side" {
    description = "side"
    got         = data.aci_rest.l3extMember_A.content.side
    want        = "A"
  }
}

data "aci_rest" "l3extIp_A" {
  dn = "${data.aci_rest.l3extMember_A.id}/addr-[1.1.1.1/24]"

  depends_on = [module.main]
}

resource "test_assertions" "l3extIp_A" {
  component = "l3extIp_A"

  equal "addr" {
    description = "addr"
    got         = data.aci_rest.l3extIp_A.content.addr
    want        = "1.1.1.1/24"
  }
}

data "aci_rest" "l3extMember_B" {
  dn = "${data.aci_rest.l3extRsPathL3OutAtt.id}/mem-B"

  depends_on = [module.main]
}

resource "test_assertions" "l3extMember_B" {
  component = "l3extMember_B"

  equal "addr" {
    description = "addr"
    got         = data.aci_rest.l3extMember_B.content.addr
    want        = "1.1.1.3/24"
  }

  equal "side" {
    description = "side"
    got         = data.aci_rest.l3extMember_B.content.side
    want        = "B"
  }
}

data "aci_rest" "l3extIp_B" {
  dn = "${data.aci_rest.l3extMember_B.id}/addr-[1.1.1.1/24]"

  depends_on = [module.main]
}

resource "test_assertions" "l3extIp_B" {
  component = "l3extIp_B"

  equal "addr" {
    description = "addr"
    got         = data.aci_rest.l3extIp_B.content.addr
    want        = "1.1.1.1/24"
  }
}

data "aci_rest" "bgpPeerP" {
  dn = "${data.aci_rest.l3extRsPathL3OutAtt.id}/peerP-[1.1.1.10]"

  depends_on = [module.main]
}

resource "test_assertions" "bgpPeerP" {
  component = "bgpPeerP"

  equal "addr" {
    description = "addr"
    got         = data.aci_rest.bgpPeerP.content.addr
    want        = "1.1.1.10"
  }

  equal "addrTCtrl" {
    description = "addrTCtrl"
    got         = data.aci_rest.bgpPeerP.content.addrTCtrl
    want        = "af-mcast,af-ucast"
  }

  equal "allowedSelfAsCnt" {
    description = "allowedSelfAsCnt"
    got         = data.aci_rest.bgpPeerP.content.allowedSelfAsCnt
    want        = "3"
  }

  equal "ctrl" {
    description = "ctrl"
    got         = data.aci_rest.bgpPeerP.content.ctrl
    want        = "send-com,send-ext-com"
  }

  equal "descr" {
    description = "descr"
    got         = data.aci_rest.bgpPeerP.content.descr
    want        = "BGP Peer"
  }

  equal "peerCtrl" {
    description = "peerCtrl"
    got         = data.aci_rest.bgpPeerP.content.peerCtrl
    want        = "bfd"
  }

  equal "privateASctrl" {
    description = "privateASctrl"
    got         = data.aci_rest.bgpPeerP.content.privateASctrl
    want        = ""
  }

  equal "ttl" {
    description = "ttl"
    got         = data.aci_rest.bgpPeerP.content.ttl
    want        = "10"
  }

  equal "weight" {
    description = "weight"
    got         = data.aci_rest.bgpPeerP.content.weight
    want        = "100"
  }
}

data "aci_rest" "bgpAsP" {
  dn = "${data.aci_rest.bgpPeerP.id}/as"

  depends_on = [module.main]
}

resource "test_assertions" "bgpAsP" {
  component = "bgpAsP"

  equal "asn" {
    description = "asn"
    got         = data.aci_rest.bgpAsP.content.asn
    want        = "12345"
  }
}
