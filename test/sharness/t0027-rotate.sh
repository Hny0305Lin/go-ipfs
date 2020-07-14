#!/usr/bin/env bash

test_description="Test rotate command"

. lib/test-lib.sh

# $1 must be one of 'rsa', 'ed25519' or '' (for default key algorithm).
test_rotate() {
        TEST_ALG=$1

        test_init_ipfs

        test_expect_success "Save first ID and key" '
        ipfs id -f="<id>" > first_id &&
        ipfs id -f="<pubkey>" > first_key
        '

        test_launch_ipfs_daemon

        test_kill_ipfs_daemon

        test_expect_success "rotating keys" '
        case $TEST_ALG in
        rsa)
                ipfs rotate -a=rsa -b=2048 --oldkey=oldkey
                ;;
        ed25519)
                ipfs rotate -a=ed25519 --oldkey=oldkey
                ;;
        *)
                ipfs rotate --oldkey=oldkey
                ;;
        esac
        '

        test_expect_success "Compare second ID and key to first" '
        ipfs id -f="<id>" > second_id &&
        ipfs id -f="<pubkey>" > second_key &&
        ! test_cmp first_id second_id &&
        ! test_cmp first_key second_key
        '

        test_expect_success "checking ID" '
        ipfs config Identity.PeerID > expected-id &&
        ipfs id -f "<id>\n" > actual-id &&
        ipfs key list -l | grep self | cut -d " " -f1 > keystore-id &&
        ipfs key list -l | grep oldkey | cut -d " " -f1 | tr -d "\n" > old-keystore-id &&
        test_cmp expected-id actual-id &&
        test_cmp expected-id keystore-id &&
        test_cmp old-keystore-id first_id
        '

        test_launch_ipfs_daemon

        test_expect_success "publish name with new and old keys" '
        echo "hello world" > msg &&
        ipfs add msg | cut -d " " -f2 | tr -d "\n" > msg_hash &&
        ipfs name publish --offline --allow-offline --key=self $(cat msg_hash) &&
        ipfs name publish --offline --allow-offline --key=oldkey $(cat msg_hash)
        '

        test_kill_ipfs_daemon

        test_done
}
test_rotate 'rsa'
test_rotate 'ed25519'
test_rotate ''
