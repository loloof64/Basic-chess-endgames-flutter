import 'dart:isolate';

import 'package:basicchessendgamestrainer/i18n/translations.g.dart';
import 'package:basicchessendgamestrainer/logic/position_generation/position_generation_from_antlr.dart';
import 'package:basicchessendgamestrainer/logic/position_generation/script_text_interpretation.dart';
import 'package:chess/chess.dart' as chess;
import 'package:basicchessendgamestrainer/components/rgpd_modal_bottom_sheet_content.dart';
import 'package:basicchessendgamestrainer/data/asset_games.dart';
import 'package:basicchessendgamestrainer/models/providers/game_provider.dart';
import 'package:basicchessendgamestrainer/pages/game_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart' show rootBundle;

const mainListItemsGap = 8.0;
const leadingImagesSize = 60.0;
const titlesFontSize = 26.0;
const rgpdWarningHeight = 200.0;
const positionGenerationErrorDialogSpacer = 20.0;

class SampleScriptGenerationParameters {
  final SendPort sendPort;
  final String gameScript;
  final TranslationsWrapper translations;

  SampleScriptGenerationParameters({
    required this.gameScript,
    required this.sendPort,
    required this.translations,
  });
}

void generatePositionFromScript(SampleScriptGenerationParameters parameters) {
  final (constraintsExpr, generationErrors) = ScriptTextTransformer(
    allConstraintsScriptText: parameters.gameScript,
    translations: parameters.translations,
  ).transformTextIntoConstraints();
  if (generationErrors.isNotEmpty) {
    parameters.sendPort.send((null, generationErrors));
  } else {
    final positionGenerator = PositionGeneratorFromAntlr();
    positionGenerator.setConstraints(constraintsExpr);
    try {
      final generatedPosition = positionGenerator.generatePosition();
      parameters.sendPort
          .send((generatedPosition, <PositionGenerationError>[]));
    } on PositionGenerationLoopException {
      parameters.sendPort.send(
        (
          null,
          <PositionGenerationError>[
            PositionGenerationError(
              parameters.translations.miscErrorDialogTitle,
              parameters.translations.failedGeneratingPosition,
            )
          ],
        ),
      );
    }
  }
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  Isolate? _positionGenerationIsolate;
  bool _isGeneratingPosition = false;

  @override
  void initState() {
    FlutterNativeSplash.remove();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showRgpdWarning());
    super.initState();
  }

  @override
  void dispose() {
    _positionGenerationIsolate?.kill(
      priority: Isolate.immediate,
    );
    super.dispose();
  }

  void _showHomePageHelpDialog() {
    showDialog(
        context: context,
        builder: (ctx2) {
          return AlertDialog(
            content: Text(t.home.help_message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx2).pop(),
                child: Text(t.misc.button_ok),
              ),
            ],
          );
        });
  }

  void _showRgpdWarning() {
    showModalBottomSheet(
        isDismissible: false,
        enableDrag: false,
        context: context,
        builder: (ctx2) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.25,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: RgpdModalBottomSheetContent(
                context: ctx2,
                height: rgpdWarningHeight,
              ),
            ),
          );
        });
  }

  Future<void> _tryGeneratingAndPlayingPositionFromSample(
      AssetGame game) async {
    final gameScript = await rootBundle.loadString(game.assetPath);
    final receivePort = ReceivePort();

    if (!mounted) return;

    setState(() {
      _isGeneratingPosition = true;
    });

    _positionGenerationIsolate = await Isolate.spawn(
      generatePositionFromScript,
      SampleScriptGenerationParameters(
        gameScript: gameScript,
        translations: TranslationsWrapper(
          miscErrorDialogTitle: t.script_parser.misc_error_dialog_title,
          missingScriptType: t.script_parser.missing_script_type,
          miscParseError: t.script_parser.misc_parse_error,
          failedGeneratingPosition: t.home.failed_generating_position,
          unrecognizedSymbol: t.script_parser.unrecognized_symbol,
          typeError: t.script_parser.type_error,
          noAntlr4Token: t.script_parser.no_antlr4_token,
          eof: t.script_parser.eof,
          variableNotAffected: t.script_parser.variable_not_affected,
          overridingPredefinedVariable:
              t.script_parser.overriding_predefined_variable,
          parseErrorDialogTitle: t.script_parser.parse_error_dialog_title,
          noViableAltException: t.script_parser.no_viable_alt_exception,
          inputMismatch: t.script_parser.input_mismatch,
          playerKingConstraint: t.script_type.player_king_constraint,
          computerKingConstraint: t.script_type.computer_king_constraint,
          kingsMutualConstraint: t.script_type.kings_mutual_constraint,
          otherPiecesCountConstraint: t.script_type.piece_kind_count_constraint,
          otherPiecesGlobalConstraint:
              t.script_type.other_pieces_global_constraint,
          otherPiecesIndexedConstraint:
              t.script_type.other_pieces_indexed_constraint,
          otherPiecesMutualConstraint:
              t.script_type.other_pieces_mutual_constraint,
        ),
        sendPort: receivePort.sendPort,
      ),
    );
    setState(() {});

    receivePort.listen((message) async {
      receivePort.close();
      _positionGenerationIsolate?.kill(
        priority: Isolate.immediate,
      );

      setState(() {
        _isGeneratingPosition = false;
      });

      final (newPosition, errors) =
          message as (String?, List<PositionGenerationError>);

      if (newPosition == null) {
        await _showGenerationErrorsPopups(errors);
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              t.home.failed_generating_position,
            ),
          ),
        );
      } else {
        _tryPlayingGeneratedPosition(newPosition, game.goal);
      }
    });
  }

  Future<void> _showGenerationErrorsPopups(
      List<PositionGenerationError> errors) async {
    for (final singleError in errors) {
      showDialog(
          context: context,
          builder: (ctx2) {
            return Dialog(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(singleError.title),
                    const SizedBox(
                      height: positionGenerationErrorDialogSpacer,
                    ),
                    Text(singleError.message),
                    const SizedBox(
                      height: positionGenerationErrorDialogSpacer,
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                          Theme.of(
                            context,
                          ).colorScheme.primary,
                        ),
                      ),
                      child: Text(
                        t.misc.button_ok,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            );
          });
    }
  }

  void _tryPlayingGeneratedPosition(String position, Goal goal) {
    final validPositionStatus = chess.Chess.validate_fen(position);
    if (!validPositionStatus['valid']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t.home.failed_loading_exercise,
          ),
        ),
      );
      return;
    }

    final playerHasWhite = position.split(' ')[1] != 'b';

    final gameNotifier = ref.read(gameProvider.notifier);
    gameNotifier.updateStartPosition(position);
    gameNotifier.updateGoal(goal);
    gameNotifier.updatePlayerHasWhite(playerHasWhite);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx2) {
        return const GamePage();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sampleGames = getAssetGames(context);
    final progressBarSize = MediaQuery.of(context).size.shortestSide * 0.80;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(t.home.title),
        actions: [
          IconButton(
            onPressed: _showHomePageHelpDialog,
            icon: const Icon(
              Icons.question_mark_rounded,
            ),
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(
                height: mainListItemsGap,
              ),
              Expanded(
                child: ListView.builder(
                    itemCount: sampleGames.length,
                    itemBuilder: (ctx2, index) {
                      final game = sampleGames[index];

                      final leadingImage = game.goal == Goal.draw
                          ? SvgPicture.asset(
                              'assets/images/handshake.svg',
                              fit: BoxFit.cover,
                              width: leadingImagesSize,
                              height: leadingImagesSize,
                            )
                          : SvgPicture.asset(
                              'assets/images/trophy.svg',
                              fit: BoxFit.cover,
                              width: leadingImagesSize,
                              height: leadingImagesSize,
                            );

                      final title = Text(
                        game.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: titlesFontSize,
                        ),
                      );

                      return ListTile(
                        leading: leadingImage,
                        title: title,
                        onTap: () =>
                            _tryGeneratingAndPlayingPositionFromSample(game),
                      );
                    }),
              ),
            ],
          ),
          if (_isGeneratingPosition)
            Center(
              child: SizedBox(
                width: progressBarSize,
                height: progressBarSize,
                child: const CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
