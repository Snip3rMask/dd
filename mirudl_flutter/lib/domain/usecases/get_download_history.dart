import '../../data/repositories/download_repository.dart';
import '../../data/models/download_entry.dart';

class GetDownloadHistory {
  final DownloadRepository _repository;
  GetDownloadHistory(this._repository);

  List<DownloadEntry> call() {
    return _repository.getHistory();
  }
}
