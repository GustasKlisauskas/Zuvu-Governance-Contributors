// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Test, console} from "forge-std/Test.sol";
import { Submission } from "../src/Submission.sol";
import { Governance } from "../src/Governance.sol";
import { ZuvuToken } from "../src/ZuvuToken.sol";

contract SubmissionTest is Test {
    Submission public sub;
    Governance public gov;
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
        gov = new Governance();
        zuvu = new ZuvuToken();

        sub.setTokenAddress(address(zuvu));
        gov.setTokenAddress(address(zuvu));
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
        assertEq(sub.submissionLength(), 1);
    }

    function test_RevertIf_RegisteringExistingSubmission() public {
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

    function test_KillSwitch() public {
        util_Spigot(s1,100);
        util_Spigot(s2,100);

        vm.prank(s1);
        sub.registerSubmission();
        sub.setKillSwitch(true);
        vm.prank(s2);
        vm.expectRevert();
        sub.registerSubmission();
        sub.setKillSwitch(false);
    }

    function test_RemoveSubmission() public {
        util_Spigot(s1,100);
        util_Spigot(s2,100);

        vm.prank(s1);
        sub.registerSubmission();

        vm.startPrank(s2);
        sub.registerSubmission();
        sub.setSubmissionMetadata("my sub", "https://example.org");
        sub.unregisterSubmission();
        vm.expectRevert();
        sub.setSubmissionMetadata("my sub", "https://example.org");
        vm.expectRevert();
        sub.unregisterSubmission();
        vm.stopPrank();

        vm.prank(s1);
        sub.unregisterSubmission();
    }
}
