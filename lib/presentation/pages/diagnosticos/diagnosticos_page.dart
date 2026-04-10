// lib/presentation/pages/diagnosticos/diagnosticos_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../injection_container.dart' as di;
import '../../../core/services/session_service.dart';
import '../../blocs/diagnostico/diagnostico_bloc.dart';
import '../../blocs/diagnostico/diagnostico_event.dart';
import '../../blocs/diagnostico/diagnostico_state.dart';
import '../../../data/models/diagnostico/diagnostico_model.dart';
import '../../theme/medical_colors.dart';

class DiagnosticosPage extends StatelessWidget {
  const DiagnosticosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final usuarioId = SessionService.instance.usuario?.id;
    return BlocProvider(
      create: (_) => di.sl<DiagnosticoBloc>()
        ..add(CargarDiagnosticosEvent(usuarioCreaId: usuarioId ?? 0)),
      child: const _DiagnosticosView(),
    );
  }
}

class _DiagnosticosView extends StatelessWidget {
  const _DiagnosticosView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnósticos'),
      ),
      body: BlocConsumer<DiagnosticoBloc, DiagnosticoState>(
        listener: (context, state) {
          if (state is ValvulopatiaConfirmada) {
            final label = state.valvulopatia ? 'confirmada' : 'descartada';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Valvulopatía $label correctamente (ID: ${state.diagnosticoId})'),
                backgroundColor: MedicalColors.successGreen,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          if (state is DiagnosticoError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.mensaje),
                backgroundColor: MedicalColors.errorRed,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        buildWhen: (_, current) =>
            current is DiagnosticoLoading ||
            current is DiagnosticoLoaded ||
            current is ValvulopatiaConfirmada ||
            current is DiagnosticoError,
        builder: (context, state) {
          if (state is DiagnosticoLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          List<DiagnosticoGrupoModel> grupos = [];
          if (state is DiagnosticoLoaded) grupos = state.grupos;
          if (state is ValvulopatiaConfirmada) grupos = state.grupos;

          if (grupos.isEmpty && state is! DiagnosticoLoading) {
            final usuarioId = SessionService.instance.usuario?.id;
            return _EmptyState(
              onRetry: () => context
                  .read<DiagnosticoBloc>()
                  .add(CargarDiagnosticosEvent(usuarioCreaId: usuarioId ?? 0)),
            );
          }

          final usuarioId = SessionService.instance.usuario?.id;
          return RefreshIndicator(
            onRefresh: () async {
              context
                  .read<DiagnosticoBloc>()
                  .add(CargarDiagnosticosEvent(usuarioCreaId: usuarioId ?? 0));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: grupos.length,
              itemBuilder: (context, index) => _GrupoCard(grupo: grupos[index]),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRetry;
  const _EmptyState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: context.hint),
          const SizedBox(height: 16),
          Text('No se encontraron diagnósticos',
              style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

// ─── Tarjeta de grupo ────────────────────────────────────────────────────────

class _GrupoCard extends StatelessWidget {
  final DiagnosticoGrupoModel grupo;
  const _GrupoCard({required this.grupo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: context.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                grupo.nombreUsuario.isNotEmpty
                    ? grupo.nombreUsuario[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            ),
          ),
          title: Text(
            grupo.nombreUsuario,
            style: theme.textTheme.titleMedium,
          ),
          subtitle: Text(
            '${grupo.totalDiagnosticos} diagnóstico${grupo.totalDiagnosticos != 1 ? 's' : ''}',
            style: theme.textTheme.bodySmall,
          ),
          children: grupo.diagnosticos
              .map((d) => _DiagnosticoTile(diagnostico: d))
              .toList(),
        ),
      ),
    );
  }
}

// ─── Tile de diagnóstico individual ──────────────────────────────────────────

class _DiagnosticoTile extends StatelessWidget {
  final DiagnosticoModel diagnostico;
  const _DiagnosticoTile({required this.diagnostico});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con ID y badges
          Row(
            children: [
              Text(
                'ID: ${diagnostico.id}',
                style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
              ),
              const Spacer(),
              _Badge(
                label: diagnostico.esNormal ? 'Normal' : 'Anormal',
                color: diagnostico.esNormal
                    ? MedicalColors.successGreen
                    : MedicalColors.warningOrange,
              ),
              const SizedBox(width: 6),
              _Badge(
                label: diagnostico.verificado ? 'Verificado' : 'Pendiente',
                color: diagnostico.verificado ? context.primary : context.hint,
              ),
              if (diagnostico.verificado) ...[
                const SizedBox(width: 6),
                _Badge(
                  label: diagnostico.valvulopatia
                      ? 'Valvulopatía +'
                      : 'Valvulopatía −',
                  color: diagnostico.valvulopatia
                      ? MedicalColors.errorRed
                      : MedicalColors.successGreen,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Detalles
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              if (diagnostico.institucion != null)
                _Detail(
                    icon: Icons.local_hospital, text: diagnostico.institucion!),
              if (diagnostico.focoNombre != null)
                _Detail(icon: Icons.hearing, text: diagnostico.focoNombre!),
              if (diagnostico.categoriaAnomaliaNombre != null)
                _Detail(
                    icon: Icons.category,
                    text: diagnostico.categoriaAnomaliaNombre!),
              if (diagnostico.edad != null)
                _Detail(icon: Icons.cake, text: '${diagnostico.edad} años'),
              if (diagnostico.genero != null)
                _Detail(icon: Icons.person, text: diagnostico.genero!),
              if (diagnostico.creadoEn != null)
                _Detail(
                    icon: Icons.calendar_today,
                    text: _formatDate(diagnostico.creadoEn!)),
            ],
          ),

          // Botón de confirmar valvulopatía
          if (!diagnostico.verificado) ...[
            const Divider(height: 20),
            Row(
              children: [
                Text(
                  '¿Valvulopatía?',
                  style: theme.textTheme.labelLarge?.copyWith(fontSize: 13),
                ),
                const Spacer(),
                _ActionButton(
                  label: 'Confirmar',
                  icon: Icons.check_circle_outline,
                  color: MedicalColors.errorRed,
                  onPressed: () => _confirm(context, true),
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  label: 'Descartar',
                  icon: Icons.cancel_outlined,
                  color: MedicalColors.successGreen,
                  onPressed: () => _confirm(context, false),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _confirm(BuildContext context, bool valvulopatia) {
    final label = valvulopatia ? 'confirmar' : 'descartar';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${valvulopatia ? "Confirmar" : "Descartar"} valvulopatía'),
        content: Text(
          '¿Estás seguro de $label la valvulopatía para el diagnóstico #${diagnostico.id}?\n\n'
          'Esta acción marcará el diagnóstico como verificado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<DiagnosticoBloc>().add(
                    ConfirmarValvulopatiaEvent(
                      diagnosticoId: diagnostico.id,
                      valvulopatia: valvulopatia,
                    ),
                  );
            },
            child: Text(
              valvulopatia ? 'Confirmar' : 'Descartar',
              style: TextStyle(
                color: valvulopatia
                    ? MedicalColors.errorRed
                    : MedicalColors.successGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

// ─── Widgets auxiliares ──────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Detail({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: context.onSurfaceSecondary),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
