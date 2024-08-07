import 'package:basicchessendgamestrainer/i18n/translations.g.dart';
import 'package:flutter/material.dart';

class AssetGame {
  final String assetPath;
  final String label;
  final bool hasWinningGoal;

  AssetGame({
    required this.assetPath,
    required this.label,
    required this.hasWinningGoal,
  });
}

List<AssetGame> getAssetGames(BuildContext context) {
  return <AssetGame>[
    AssetGame(
      assetPath: 'assets/sample_scripts/kq_k.txt',
      label: t.sample_script.kq_k,
      hasWinningGoal: true,
    ),
    AssetGame(
      assetPath: 'assets/sample_scripts/kr_k.txt',
      label: t.sample_script.kr_k,
      hasWinningGoal: true,
    ),
    AssetGame(
      assetPath: 'assets/sample_scripts/krr_k.txt',
      label: t.sample_script.krr_k,
      hasWinningGoal: true,
    ),
    AssetGame(
      assetPath: 'assets/sample_scripts/kbb_k.txt',
      label: t.sample_script.kbb_k,
      hasWinningGoal: true,
    ),
    AssetGame(
      assetPath: 'assets/sample_scripts/kp_k_1.txt',
      label: t.sample_script.kp_k1,
      hasWinningGoal: true,
    ),
    AssetGame(
      assetPath: 'assets/sample_scripts/kp_k_2.txt',
      label: t.sample_script.kp_k2,
      hasWinningGoal: false,
    ),
    AssetGame(
      assetPath: 'assets/sample_scripts/kppp_kppp.txt',
      label: t.sample_script.kppp_kppp,
      hasWinningGoal: true,
    ),
    AssetGame(
      assetPath: 'assets/sample_scripts/lucena_rook_ending.txt',
      label: t.sample_script.rook_ending_lucena,
      hasWinningGoal: true,
    ),
    AssetGame(
      assetPath: 'assets/sample_scripts/philidor_rook_ending.txt',
      label: t.sample_script.rook_ending_philidor,
      hasWinningGoal: false,
    )
  ];
}
