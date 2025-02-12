// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Test, console} from "forge-std/Test.sol";
import { Submission } from "../src/Submission.sol";
import { ZuvuToken } from "../src/ZuvuToken.sol";

contract SubmissionTest is Test {
    Submission public sub;
    ZuvuToken public zuvu;

    // Test addresses
    address constant s1 = address(0xa1);
    address constant s2 = address(0xa2);
    address constant s3 = address(0xa3);
    address constant s4 = address(0xa4);
    address constant s5 = address(0xa5);

    uint128 constant UINT128_MAX = 128**2-1;

    function setUp() public {
        sub = new Submission(100);
        zuvu = new ZuvuToken();

        sub.setTokenAddress(address(zuvu));
        zuvu.setGovernanceContract(address(sub));
    }

    function util_convertZuvuDecimals(uint256 a) public view returns(uint256) {
        return a * 10 ** zuvu.decimals();
    }


    function util_Spigot(address to, uint256 amount) public {
        deal(address(zuvu), to, amount);
        vm.prank(to);
        zuvu.approve(address(sub), amount);
    }

    function test_addRemoveSubmission() public {
        assertEq(uint256(sub.submissionLength()), 0);

        util_Spigot(s1,50);
        vm.prank(s1);

        vm.expectRevert();
        sub.registerSubmission();

        util_Spigot(s1,100);
        vm.startPrank(s1);
        sub.registerSubmission();

        assertEq(uint256(sub.submissionLength()), 1);
        vm.expectRevert();
        sub.registerSubmission();
        vm.stopPrank();
        //assertEq(sub.submissionLength, 1);
        //sub.registerSubmission();

    }

    function test_RevertIf_RegisteringExistingGovernor() public {
        util_Spigot(s1,100);
        util_Spigot(s2,100);
        util_Spigot(s3,100);
        util_Spigot(s4,100);

        vm.prank(s1);
        sub.registerSubmission();

        vm.expectRevert();
        vm.prank(s1);
        sub.registerSubmission();

        vm.prank(s2);
        sub.registerSubmission();
        vm.prank(s3);
        sub.registerSubmission();
        vm.prank(s4);
        sub.registerSubmission();

        vm.expectRevert();
        vm.prank(s3);
        sub.registerSubmission();
    }

    //function test_Remove() public {
    //    vm.prank(g1);
    //    sub.registerGovernor();
    //    vm.prank(g2);
    //    sub.registerGovernor();
    //    vm.prank(g3);
    //    sub.registerGovernor();
    //    vm.prank(g4);
    //    sub.registerGovernor();

    //    vm.prank(g2);
    //    sub.unregisterGovernor();

    //    assertEq(sub.governorLength(), 3);

    //    vm.expectRevert("Governor not registered");
    //    vm.prank(g2);
    //    sub.unregisterGovernor();

    //    vm.prank(g3);
    //    sub.unregisterGovernor();
    //    vm.prank(g4);
    //    sub.unregisterGovernor();
    //    assertEq(sub.governorLength(), 1);
    //    vm.prank(g1);
    //    sub.unregisterGovernor();
    //    assertEq(sub.governorLength(), 0);

    //    vm.prank(g2);
    //    sub.registerGovernor();
    //    vm.prank(g1);
    //    sub.registerGovernor();

    //    assertEq(sub.governorLength(), 2);
    //}

    //function test_Stake() public {
    //    vm.prank(g1);
    //    sub.registerGovernor();
    //    vm.prank(g2);
    //    sub.registerGovernor();
    //    vm.prank(g3);
    //    sub.registerGovernor();
    //    vm.prank(g4);
    //    sub.registerGovernor();

    //    util_Spigot(g1,1003);
    //    vm.prank(g1);
    //    sub.setStake(g1, 1003);
    //    
    //    
    //    util_Spigot(g2,3);
    //    vm.prank(g2);
    //    sub.setStake(g2, 3);

    //    util_Spigot(g3,102);
    //    vm.prank(g3);
    //    sub.setStake(g3, 102);

    //    util_Spigot(g4,2014);
    //    vm.prank(g4);
    //    sub.setStake(g4, 2014);

    //    vm.expectRevert("Governor not registered");
    //    vm.prank(address(1337));
    //    sub.setStake(address(1337), 314);

    //    vm.expectRevert(); // Insufficient balance
    //    vm.prank(g1);
    //    sub.setStake(g1, 1004);

    //    assertEq(sub.getGovernorTotalStake(g1), 1003);
    //    assertEq(sub.getGovernorTotalStake(g2), 3);
    //    assertEq(sub.getGovernorTotalStake(g3), 102);
    //    assertEq(sub.getGovernorTotalStake(g4), 2014);

    //    vm.expectRevert(); // Insufficient balance
    //    vm.prank(g2);
    //    sub.setStake(g1, 12);

    //    util_Spigot(g2,12);
    //    vm.prank(g2);
    //    sub.setStake(g1, 12);

    //    util_Spigot(g3,13);
    //    vm.prank(g3);
    //    sub.setStake(g1, 13);

    //    util_Spigot(g1,21);
    //    vm.prank(g1);
    //    sub.setStake(g2, 21);

    //    util_Spigot(g3,23);
    //    vm.prank(g3);
    //    sub.setStake(g2, 23);

    //    assertEq(sub.getGovernorTotalStake(g1), 1003 + 12 + 13);
    //    assertEq(sub.getGovernorTotalStake(g2), 3 + 21 + 23);
    //    assertEq(sub.getGovernorTotalStake(g3), 102);
    //    assertEq(sub.getGovernorTotalStake(g4), 2014);
    //}

    //function test_GetTopGovernors() public {
    //    uint8 governorAmount = 36;

    //    for(uint256 i = 0; i < governorAmount; i++) {
    //        address governor = address(100 + uint160(i));
    //        
    //        vm.prank(governor);
    //        sub.registerGovernor();
    //        uint256 s = utils.getRandStake(i);
    //        util_Spigot(governor, s);

    //        vm.prank(governor);
    //        sub.setStake(governor,s);
    //    }

    //    Governance.GovernorStake[] memory top = sub.getTopGovernorsByStake(governorAmount);

    //    assertEq(top.length, governorAmount);

    //    vm.expectRevert("Invalid value for N");
    //    sub.getTopGovernorsByStake(governorAmount+1);

    //    Governance.GovernorStake[] memory topThree = sub.getTopGovernorsByStake(3);

    //    assertEq(topThree[0].governor, top[0].governor);
    //    assertEq(topThree[1].governor, top[1].governor);
    //    assertEq(topThree[2].governor, top[2].governor);


    //    Governance.GovernorStake memory currentGovernor = top[0];
    //    for(uint256 i = 1; i < governorAmount-1; i++) {
    //        Governance.GovernorStake memory nextGovernor = top[i];

    //        assertGe(currentGovernor.totalStake, nextGovernor.totalStake); // check if current governor stake >= nextGovernor

    //        currentGovernor = nextGovernor;
    //    }

    //    vm.expectRevert("Invalid value for N");
    //    sub.getTopGovernorsByStake(0);
    //}

    //function test_StakingRewards() public {
    //    vm.prank(g1);
    //    sub.registerGovernor();
    //    vm.prank(g2);
    //    sub.registerGovernor();
    //    vm.prank(g3);
    //    sub.registerGovernor();
    //    vm.prank(g4);
    //    sub.registerGovernor();
    //    vm.prank(g5);
    //    sub.registerGovernor();

    //    util_Spigot(g1,600);
    //    vm.prank(g1);
    //    sub.setStake(g1,600);

    //    util_Spigot(g2,400);
    //    vm.prank(g2);
    //    sub.setStake(g2,400);

    //    util_Spigot(g3,300);
    //    vm.prank(g3);
    //    sub.setStake(g3,300);

    //    util_Spigot(g4,200);
    //    vm.prank(g4);
    //    sub.setStake(g4,200);

    //    util_Spigot(g5,150);
    //    vm.prank(g5);
    //    sub.setStake(g5,150);

    //    vm.prank(g1);
    //    sub.voteStake(0);
    //    vm.prank(g2);
    //    sub.voteStake(20);
    //    vm.prank(g3);
    //    sub.voteStake(100);
    //    vm.prank(g4);
    //    sub.voteStake(100);
    //    vm.prank(g5);
    //    sub.voteStake(100);

    //    vm.expectRevert("percentage must be between 0 and 100");
    //    vm.prank(g5);
    //    sub.voteStake(101);

    //    vm.expectRevert("Governor not registered");
    //    vm.prank(address(1337));
    //    sub.voteStake(15);

    //    uint256 rew = sub.getStakeVote();
    //    assertEq(rew,20);
    //    
    //    skip(1 days);
    //    zuvu.mintRewards();
    //    
    //    uint256 accuracyTreshold = util_convertZuvuDecimals(1); // check if rewards are accurate within 1 token;

    //    assertApproxEqAbs(sub.stakerRewards(g1), util_convertZuvuDecimals(72_727), accuracyTreshold);  // the reward should be 72_727.2727...
    //    vm.prank(g1);
    //    sub.claimReward();
    //    assertEq(sub.stakerRewards(g1), 0); 
    //    assertApproxEqAbs(zuvu.balanceOf(g1), util_convertZuvuDecimals(72_727), accuracyTreshold);  // the reward should be 72_727.2727...

    //    assertApproxEqAbs(sub.stakerRewards(g2), util_convertZuvuDecimals(48_484), accuracyTreshold);  // the reward should be 72_727.2727...
    //    assertApproxEqAbs(sub.stakerRewards(g3), util_convertZuvuDecimals(36_363), accuracyTreshold);  // the reward should be 72_727.2727...
    //    assertApproxEqAbs(sub.stakerRewards(g4), util_convertZuvuDecimals(24_242), accuracyTreshold);  // the reward should be 72_727.2727...
    //    assertApproxEqAbs(sub.stakerRewards(g5), util_convertZuvuDecimals(18_181), accuracyTreshold);  // the reward should be 72_727.2727...
    //}
}

//contract GovernanceTestFuzz is Test {
    //Governance public gov;
    //ZuvuToken public zuvu;
    //GovernanceUtils public utils;

    //constructor() {
    //    gov = new Governance();
    //    zuvu = new ZuvuToken();

    //    gov.setTokenAddress(address(zuvu));
    //    zuvu.setGovernanceContract(address(gov));
    //    utils = new GovernanceUtils();
    //}

    //function util_convertZuvuDecimals(uint256 a) public view returns(uint256) {
    //    return a * 10 ** zuvu.decimals();
    //}

    //function util_Spigot(address to, uint256 amount) public {
    //    deal(address(zuvu), to, amount);
    //    vm.prank(to);
    //    zuvu.approve(address(gov), amount);
    //}

    //function testFuzz_ListSize(uint8 size) public {
    //    assertEq(gov.governorLength(), 0);
    //    
    //    for(uint128 i = 0; i < size; i++) {
    //        assertEq(gov.governorLength(), i);
    //        vm.prank(address(100 + uint160(i)));
    //        gov.registerGovernor();
    //    }
    //    assertEq(gov.governorLength(), size);
    //}

    //// warning: this test may take a long time to run!
    //function testFuzz_StakingSort(uint16 seed) public {
    //    uint8 governorAmount = uint8(seed);
    //    if(governorAmount == 0){
    //        return;
    //    }

    //    uint256 govSeed =  uint256(keccak256(abi.encodePacked(seed, uint24(1337))));

    //    for(uint256 i = 0; i < governorAmount; i++) {
    //        address governor = address(uint160(govSeed + i));
    //        uint256 stake = utils.getRandStake(i + seed);

    //        util_Spigot(governor,stake);
    //        vm.startPrank(governor);
    //        gov.registerGovernor();
    //        gov.setStake(governor,stake);
    //        vm.stopPrank();

    //        if(i % 3 == 2){
    //            governor = address(uint160(govSeed + (i - 1)));
    //            stake = utils.getRandStake(314152960 + i + seed);
    //            util_Spigot(governor,stake);
    //            vm.prank(governor);
    //            gov.setStake(governor,stake);
    //        }
    //    }

    //    uint8 topAmount = 64;
    //    if(governorAmount < topAmount){
    //        topAmount = governorAmount;
    //    }

    //    Governance.GovernorStake[] memory top = gov.getTopGovernorsByStake(topAmount);

    //    address currentGovernor = top[0].governor;
    //    for(uint256 i = 1; i < topAmount-1; i++) {
    //        address nextGovernor = top[i].governor;

    //        uint256 stakeCurrent = gov.getGovernorTotalStake(currentGovernor);
    //        uint256 stakeNext = gov.getGovernorTotalStake(nextGovernor);

    //        assertGe(stakeCurrent,stakeNext); // check if current governor stake >= nextGovernor
    //        currentGovernor = nextGovernor;
    //    }
    //}
//}
