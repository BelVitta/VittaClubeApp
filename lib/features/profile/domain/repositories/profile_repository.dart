import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/profile_entity.dart';

abstract class ProfileRepository {
  /// Retorna o perfil do usuário logado. `null` se não autenticado.
  Future<Either<Failure, ProfileEntity?>> getCurrent();
}
