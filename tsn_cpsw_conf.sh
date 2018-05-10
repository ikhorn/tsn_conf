#!/bin/sh

DEST_MAC="18:03:73:66:87:42"
CLASS_A_RATE=40000
CLASS_B_RATE=20000

# increase number of tx queues for eth interface
ethtool -L eth0 rx 1 tx 4

# create sk_prio->tc->txq mapping
# map sk_prio: 3pri -> tc0, 2pri -> tc1, (0,1,4-7) -> tc3
# map tc to txq, assign tc0 -> txq0, tc1 -> txq1, tc2 -> (txq2, txq3)
tc qdisc replace dev eth0 handle 100: parent root mqprio num_tc 3 \
	map 2 2 1 0 2 2 2 2 2 2 2 2 2 2 2 2 queues 1@0 1@1 2@2 hw 1

# set rate limitation for tx queues 0 and 1. Comment if need test only fifo
# shapers. Or one of them.
echo $(($CLASS_A_RATE/1000)) > /sys/class/net/eth0/queues/tx-0/tx_maxrate
echo $(($CLASS_B_RATE/1000)) > /sys/class/net/eth0/queues/tx-1/tx_maxrate

# set rate limitation for fifo shapers (traffic classes 0 and 1)
# set rate limitation for tc0 40Mbit. Comment if need to test cpdma shaper only,
# or just test sk->prio->tc->txq mapping.
tc qdisc replace dev eth0 parent 100:1 cbs locredit -1470 hicredit 30 \
sendslope -980000 idleslope $CLASS_A_RATE offload 1

# set rate limitation for tc1 20Mbit. Comment if need to test cpdma shaper only,
# or just test sk->prio->tc->txq mapping.
tc qdisc replace dev eth0 parent 100:2 cbs locredit -1470 hicredit 30 \
sendslope -980000 idleslope $CLASS_B_RATE offload 1

# add vlan with vid 100
vconfig add eth0 100

# create sk_prio->L2 mapping
vconfig set_egress_map eth0.100 0 0
vconfig set_egress_map eth0.100 1 1
vconfig set_egress_map eth0.100 2 2
vconfig set_egress_map eth0.100 3 3
vconfig set_egress_map eth0.100 4 4
vconfig set_egress_map eth0.100 5 5
vconfig set_egress_map eth0.100 6 6
vconfig set_egress_map eth0.100 7 7


# Run talker. Comment/uncomment traffic classes you need to test.
# run talker for class A:
#./tsn_talker -d $DEST_MAC -i eth0.100 -p 3 -s 1500

# run talker for class B:
./tsn_talker -d $DEST_MAC -i eth0.100 -p 2 -s 1500

# run talker for rest:
# ./tsn_talker -d $DEST_MAC -i eth0.100 -p 1 -s 1500

# on host part run:
# ./tsn_listener -d $DEST_MAC -i enp5s0 -s 1500
