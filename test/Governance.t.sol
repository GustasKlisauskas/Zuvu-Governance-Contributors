// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Test, console} from "forge-std/Test.sol";
import { Governance } from "../src/Governance.sol";
import { Submission } from "../src/Submission.sol";
import { ZuvuToken } from "../src/ZuvuToken.sol";

contract GovernanceUtils {
    function getRandStake(uint256 seed) public pure returns(uint256) {
        return uint256(keccak256(abi.encodePacked(seed))) >> 16;
    }
}

contract GovernanceTest is Test {
    Governance public gov;
    ZuvuToken public zuvu;
    Submission public sub;
    GovernanceUtils public utils;

    // Test addresses
    address constant g1 = address(0xa1);
    address constant g2 = address(0xa2);
    address constant g3 = address(0xa3);
    address constant g4 = address(0xa4);
    address constant g5 = address(0xa5);

    uint128 constant UINT128_MAX = 128**2-1;

    function setUp() public {
        gov = new Governance();
        zuvu = new ZuvuToken();
        sub = new Submission(0);

        gov.setTokenAddress(address(zuvu));
        sub.setTokenAddress(address(zuvu));

        zuvu.setGovernanceContract(address(gov));
        zuvu.setSubmissionContract(address(sub));

        utils = new GovernanceUtils();
    }

    function util_convertZuvuDecimals(uint256 a) public view returns(uint256) {
        return a * 10 ** zuvu.decimals();
    }


    function util_Spigot(address to, uint256 amount) public {
        deal(address(zuvu), to, amount);
        vm.prank(to);
        zuvu.approve(address(gov), amount);
    }

    function test_RevertIf_RegisteringExistingGovernor() public {
        vm.prank(g1);
        gov.registerGovernor();

        vm.expectRevert("Governor already registered");
        vm.prank(g1);
        gov.registerGovernor();

        vm.prank(g2);
        gov.registerGovernor();
        vm.prank(g3);
        gov.registerGovernor();
        vm.prank(g4);
        gov.registerGovernor();

        vm.expectRevert("Governor already registered");
        vm.prank(g2);
        gov.registerGovernor();
    }

    function test_Remove() public {
        vm.prank(g1);
        gov.registerGovernor();
        vm.prank(g2);
        gov.registerGovernor();
        vm.prank(g3);
        gov.registerGovernor();
        vm.prank(g4);
        gov.registerGovernor();

        vm.prank(g2);
        gov.unregisterGovernor();

        assertEq(gov.governorLength(), 3);

        vm.expectRevert("Governor not registered");
        vm.prank(g2);
        gov.unregisterGovernor();

        vm.prank(g3);
        gov.unregisterGovernor();
        vm.prank(g4);
        gov.unregisterGovernor();
        assertEq(gov.governorLength(), 1);
        vm.prank(g1);
        gov.unregisterGovernor();
        assertEq(gov.governorLength(), 0);

        vm.prank(g2);
        gov.registerGovernor();
        vm.prank(g1);
        gov.registerGovernor();

        assertEq(gov.governorLength(), 2);
    }

    function test_Stake() public {
        vm.prank(g1);
        gov.registerGovernor();
        vm.prank(g2);
        gov.registerGovernor();
        vm.prank(g3);
        gov.registerGovernor();
        vm.prank(g4);
        gov.registerGovernor();

        util_Spigot(g1,1003);
        vm.prank(g1);
        gov.setStake(g1, 1003);
        
        
        util_Spigot(g2,3);
        vm.prank(g2);
        gov.setStake(g2, 3);

        util_Spigot(g3,102);
        vm.prank(g3);
        gov.setStake(g3, 102);

        util_Spigot(g4,2014);
        vm.prank(g4);
        gov.setStake(g4, 2014);

        vm.expectRevert("Governor not registered");
        vm.prank(address(1337));
        gov.setStake(address(1337), 314);

        vm.expectRevert(); // Insufficient balance
        vm.prank(g1);
        gov.setStake(g1, 1004);

        assertEq(gov.getGovernorTotalStake(g1), 1003);
        assertEq(gov.getGovernorTotalStake(g2), 3);
        assertEq(gov.getGovernorTotalStake(g3), 102);
        assertEq(gov.getGovernorTotalStake(g4), 2014);

        vm.expectRevert(); // Insufficient balance
        vm.prank(g2);
        gov.setStake(g1, 12);

        util_Spigot(g2,12);
        vm.prank(g2);
        gov.setStake(g1, 12);

        util_Spigot(g3,13);
        vm.prank(g3);
        gov.setStake(g1, 13);

        util_Spigot(g1,21);
        vm.prank(g1);
        gov.setStake(g2, 21);

        util_Spigot(g3,23);
        vm.prank(g3);
        gov.setStake(g2, 23);

        assertEq(gov.getGovernorTotalStake(g1), 1003 + 12 + 13);
        assertEq(gov.getGovernorTotalStake(g2), 3 + 21 + 23);
        assertEq(gov.getGovernorTotalStake(g3), 102);
        assertEq(gov.getGovernorTotalStake(g4), 2014);
    }

    function test_GetTopGovernors() public {
        uint8 governorAmount = 36;

        for(uint256 i = 0; i < governorAmount; i++) {
            address governor = address(100 + uint160(i));
            
            vm.prank(governor);
            gov.registerGovernor();
            uint256 s = utils.getRandStake(i);
            util_Spigot(governor, s);

            vm.prank(governor);
            gov.setStake(governor,s);
        }

        Governance.GovernorStake[] memory top = gov.getTopGovernorsByStake(governorAmount);

        assertEq(top.length, governorAmount);

        vm.expectRevert("Invalid value for N");
        gov.getTopGovernorsByStake(governorAmount+1);

        Governance.GovernorStake[] memory topThree = gov.getTopGovernorsByStake(3);

        assertEq(topThree[0].governor, top[0].governor);
        assertEq(topThree[1].governor, top[1].governor);
        assertEq(topThree[2].governor, top[2].governor);


        Governance.GovernorStake memory currentGovernor = top[0];
        for(uint256 i = 1; i < governorAmount-1; i++) {
            Governance.GovernorStake memory nextGovernor = top[i];

            assertGe(currentGovernor.totalStake, nextGovernor.totalStake); // check if current governor stake >= nextGovernor

            currentGovernor = nextGovernor;
        }

        vm.expectRevert("Invalid value for N");
        gov.getTopGovernorsByStake(0);
    }

    function test_StakingRewards() public {
        vm.prank(g1);
        gov.registerGovernor();
        vm.prank(g2);
        gov.registerGovernor();
        vm.prank(g3);
        gov.registerGovernor();
        vm.prank(g4);
        gov.registerGovernor();
        vm.prank(g5);
        gov.registerGovernor();

        util_Spigot(g1,600);
        vm.prank(g1);
        gov.setStake(g1,600);

        util_Spigot(g2,400);
        vm.prank(g2);
        gov.setStake(g2,400);

        util_Spigot(g3,300);
        vm.prank(g3);
        gov.setStake(g3,300);

        util_Spigot(g4,200);
        vm.prank(g4);
        gov.setStake(g4,200);

        util_Spigot(g5,150);
        vm.prank(g5);
        gov.setStake(g5,150);

        vm.prank(g1);
        gov.voteStake(0);
        vm.prank(g2);
        gov.voteStake(20);
        vm.prank(g3);
        gov.voteStake(100);
        vm.prank(g4);
        gov.voteStake(100);
        vm.prank(g5);
        gov.voteStake(100);

        vm.expectRevert("percentage must be between 0 and 100");
        vm.prank(g5);
        gov.voteStake(101);

        vm.expectRevert("Governor not registered");
        vm.prank(address(1337));
        gov.voteStake(15);

        uint256 rew = gov.getStakeVote();
        assertEq(rew,20);
        skip(1 days);

        zuvu.mintRewards();
        uint256 accuracyTreshold = util_convertZuvuDecimals(1); // check if rewards are accurate within 1 token;

        assertApproxEqAbs(gov.stakerRewards(g1), util_convertZuvuDecimals(36_3636), accuracyTreshold);  // the reward should be 72_727.2727...
        vm.prank(g1);
        gov.claimReward();
        assertEq(gov.stakerRewards(g1), 0); 
        assertApproxEqAbs(zuvu.balanceOf(g1), util_convertZuvuDecimals(363_636), accuracyTreshold);  // the reward should be 72_727.2727...

        assertApproxEqAbs(gov.stakerRewards(g2), util_convertZuvuDecimals(242_424), accuracyTreshold);  // the reward should be 72_727.2727...
        assertApproxEqAbs(gov.stakerRewards(g3), util_convertZuvuDecimals(181_818), accuracyTreshold);  // the reward should be 72_727.2727...
        assertApproxEqAbs(gov.stakerRewards(g4), util_convertZuvuDecimals(121_212), accuracyTreshold);  // the reward should be 72_727.2727...
        assertApproxEqAbs(gov.stakerRewards(g5), util_convertZuvuDecimals(90_909), accuracyTreshold);  // the reward should be 72_727.2727...
    }

    function test_GetSubmissions() public {
        vm.prank(g1);
        gov.registerGovernor();
        vm.prank(g2);
        gov.registerGovernor();
        vm.prank(g3);
        gov.registerGovernor();
        vm.prank(g4);
        gov.registerGovernor();
        vm.prank(g5);
        gov.registerGovernor();

        util_Spigot(g1,600);
        vm.prank(g1);
        gov.setStake(g1,600);

        util_Spigot(g2,400);
        vm.prank(g2);
        gov.setStake(g2,400);

        util_Spigot(g3,300);
        vm.prank(g3);
        gov.setStake(g3,300);

        util_Spigot(g4,200);
        vm.prank(g4);
        gov.setStake(g4,200);

        util_Spigot(g5,150);
        vm.prank(g5);
        gov.setStake(g5,150);

            
        address e1 = address(0xa10001);
        address e2 = address(0xa10002);
        address e3 = address(0xa10003);
        address e4 = address(0xa10004);

        vm.startPrank(g1);
        gov.voteForSubmission(e1, 50);
        gov.voteForSubmission(e2, 25);
        gov.voteForSubmission(e3, 15);
        gov.voteForSubmission(e4, 10);
        vm.stopPrank();

        vm.startPrank(g2);
        gov.voteForSubmission(e1, 25);
        gov.voteForSubmission(e2, 25);
        gov.voteForSubmission(e3, 25);
        gov.voteForSubmission(e4, 25);
        vm.stopPrank();

        vm.startPrank(g3);
        gov.voteForSubmission(e1, 25);
        gov.voteForSubmission(e2, 25);
        gov.voteForSubmission(e3, 25);
        gov.voteForSubmission(address(0xa12345), 10);
        vm.stopPrank();

        vm.startPrank(g4);
        gov.voteForSubmission(e4, 50);
        vm.stopPrank();

        vm.startPrank(g5);
        gov.voteForSubmission(e1, 30);
        vm.stopPrank();

        for(uint256 i = 0; i < 1000; i++) {
            address govgov = address(uint160(0xbabababababab) + (uint160(i) % 64));
            address subsub = address(uint160(0xa12345)+ uint160(i));
            util_Spigot(govgov,100 + i);
            vm.startPrank(govgov);
            if(i < 64){
                gov.registerGovernor();
            }
            gov.setStake(govgov,100 + i);
            gov.voteForSubmission(subsub, uint8((i*10) % 50)+1);
            vm.stopPrank();
        }

        address[] memory topSubs = gov.getTopSubmissions(); 
        assertEq(topSubs.length, 640); // should be the top governors * max votes per governor

        (Governance.SubmissionReward[] memory rewards, uint256 total) = gov.getSubmissionRewards();

        for(uint256 i = 0; i < rewards.length; i++) {
            console.log("sr",rewards[i].submission, rewards[i].reward,(rewards[i].reward * 10 ** 8) / (total));
        }

        console.log("tt", total);
    }

}

contract GovernanceTestFuzz is Test {
    Governance public gov;
    ZuvuToken public zuvu;
    GovernanceUtils public utils;

    constructor() {
        gov = new Governance();
        zuvu = new ZuvuToken();

        gov.setTokenAddress(address(zuvu));
        zuvu.setGovernanceContract(address(gov));
        utils = new GovernanceUtils();
    }

    function util_convertZuvuDecimals(uint256 a) public view returns(uint256) {
        return a * 10 ** zuvu.decimals();
    }

    function util_Spigot(address to, uint256 amount) public {
        deal(address(zuvu), to, amount);
        vm.prank(to);
        zuvu.approve(address(gov), amount);
    }

    function testFuzz_ListSize(uint8 size) public {
        assertEq(gov.governorLength(), 0);
        
        for(uint128 i = 0; i < size; i++) {
            assertEq(gov.governorLength(), i);
            vm.prank(address(100 + uint160(i)));
            gov.registerGovernor();
        }
        assertEq(gov.governorLength(), size);
    }

    // warning: this test may take a long time to run!
    function testFuzz_StakingSort(uint16 seed) public {
        uint8 governorAmount = uint8(seed);
        if(governorAmount == 0){
            return;
        }

        uint256 govSeed =  uint256(keccak256(abi.encodePacked(seed, uint24(1337))));

        for(uint256 i = 0; i < governorAmount; i++) {
            address governor = address(uint160(govSeed + i));
            uint256 stake = utils.getRandStake(i + seed);

            util_Spigot(governor,stake);
            vm.startPrank(governor);
            gov.registerGovernor();
            gov.setStake(governor,stake);
            gov.voteForSubmission(address(uint160(governor) + 0xc0ffebabe), 5);
            vm.stopPrank();

            if(i % 3 == 2){
                governor = address(uint160(govSeed + (i - 1)));
                stake = utils.getRandStake(314152960 + i + seed);
                util_Spigot(governor,stake);
                vm.startPrank(governor);
                gov.setStake(governor,stake);
                vm.stopPrank();
            }
        }

        uint8 topAmount = 64;
        if(governorAmount < topAmount){
            topAmount = governorAmount;
        }

        Governance.GovernorStake[] memory top = gov.getTopGovernorsByStake(topAmount);

        address currentGovernor = top[0].governor;
        for(uint256 i = 1; i < topAmount-1; i++) {
            address nextGovernor = top[i].governor;

            uint256 stakeCurrent = gov.getGovernorTotalStake(currentGovernor);
            uint256 stakeNext = gov.getGovernorTotalStake(nextGovernor);

            assertGe(stakeCurrent,stakeNext); // check if current governor stake >= nextGovernor
            currentGovernor = nextGovernor;
        }

        (Governance.SubmissionReward[] memory rewards, uint256 total) = gov.getSubmissionRewards();

        for(uint256 i = 0; i < rewards.length; i++) {
            console.log("sr",rewards[i].submission, rewards[i].reward);
        }
    }
}
