// TECHNICAL ARCHITECTURE IMPROVEMENTS NEEDED

/* 
===================================== 
CURRENT ARCHITECTURE ANALYSIS
===================================== 
*/

✅ STRENGTHS:
- Good separation of concerns (screens, models, services, helpers)
- Provider pattern for state management
- Proper localization setup
- SQLite database implementation
- Theme system with Material 3

❌ WEAKNESSES:
- No dependency injection
- Limited error handling
- No offline-first architecture
- No caching strategies
- Basic testing coverage
- No CI/CD pipeline

/* 
===================================== 
RECOMMENDED ARCHITECTURE UPGRADES
===================================== 
*/

// 1. DEPENDENCY INJECTION
// Replace manual dependencies with GetIt or Riverpod
abstract class ServiceLocator {
  static void setup() {
    GetIt.instance.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper());
    GetIt.instance.registerLazySingleton<APIService>(() => APIService());
    GetIt.instance.registerLazySingleton<AuthService>(() => AuthService());
    GetIt.instance.registerLazySingleton<OCRService>(() => OCRService());
  }
}

// 2. REPOSITORY PATTERN
abstract class ExpenseRepository {
  Future<List<Expense>> getAllExpenses();
  Future<Expense> getExpenseById(String id);
  Future<void> createExpense(Expense expense);
  Future<void> updateExpense(Expense expense);
  Future<void> deleteExpense(String id);
}

class ExpenseRepositoryImpl implements ExpenseRepository {
  final DatabaseHelper _db;
  final APIService _api;
  final CacheService _cache;

  ExpenseRepositoryImpl(this._db, this._api, this._cache);

  @override
  Future<List<Expense>> getAllExpenses() async {
    // Try cache first
    final cached = await _cache.getExpenses();
    if (cached.isNotEmpty) return cached;

    // Try local database
    final local = await _db.getExpenses();
    if (local.isNotEmpty) {
      await _cache.cacheExpenses(local);
      return local;
    }

    // Try API as last resort
    try {
      final remote = await _api.getExpenses();
      await _db.insertExpenses(remote);
      await _cache.cacheExpenses(remote);
      return remote;
    } catch (e) {
      throw DatabaseException('Failed to fetch expenses: $e');
    }
  }
}

// 3. BLOC/CUBIT STATE MANAGEMENT
class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final ExpenseRepository _repository;

  ExpenseBloc(this._repository) : super(ExpenseInitial()) {
    on<LoadExpenses>(_onLoadExpenses);
    on<AddExpense>(_onAddExpense);
    on<UpdateExpense>(_onUpdateExpense);
    on<DeleteExpense>(_onDeleteExpense);
  }

  Future<void> _onLoadExpenses(LoadExpenses event, Emitter<ExpenseState> emit) async {
    emit(ExpenseLoading());
    try {
      final expenses = await _repository.getAllExpenses();
      emit(ExpenseLoaded(expenses));
    } catch (e) {
      emit(ExpenseError(e.toString()));
    }
  }
}

// 4. ERROR HANDLING & LOGGING
class AppException implements Exception {
  final String message;
  final String code;
  final dynamic originalError;

  AppException(this.message, this.code, [this.originalError]);
}

class DatabaseException extends AppException {
  DatabaseException(String message) : super(message, 'DB_ERROR');
}

class NetworkException extends AppException {
  NetworkException(String message) : super(message, 'NETWORK_ERROR');
}

class LoggingService {
  static void logError(String message, dynamic error, [StackTrace? stackTrace]) {
    // Integrate with Firebase Crashlytics or Sentry
    print('ERROR: $message - $error');
    if (stackTrace != null) print('Stack trace: $stackTrace');
  }
}

// 5. API SERVICE LAYER
class APIService {
  final Dio _dio;
  final String baseUrl = 'https://api.expense-tracker.com';

  APIService(this._dio) {
    _dio.options.baseUrl = baseUrl;
    _dio.interceptors.add(AuthInterceptor());
    _dio.interceptors.add(LoggingInterceptor());
  }

  Future<List<Expense>> getExpenses() async {
    try {
      final response = await _dio.get('/expenses');
      return (response.data as List)
          .map((json) => Expense.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw NetworkException('Failed to fetch expenses: ${e.message}');
    }
  }
}

// 6. CACHING LAYER
abstract class CacheService {
  Future<List<Expense>> getExpenses();
  Future<void> cacheExpenses(List<Expense> expenses);
  Future<void> clearCache();
}

class HiveCacheService implements CacheService {
  final Box<Expense> _expenseBox;

  HiveCacheService(this._expenseBox);

  @override
  Future<List<Expense>> getExpenses() async {
    return _expenseBox.values.toList();
  }

  @override
  Future<void> cacheExpenses(List<Expense> expenses) async {
    await _expenseBox.clear();
    await _expenseBox.addAll(expenses);
  }
}

// 7. OFFLINE-FIRST ARCHITECTURE
class SyncService {
  final APIService _api;
  final DatabaseHelper _db;
  final ConnectivityService _connectivity;

  SyncService(this._api, this._db, this._connectivity);

  Future<void> syncData() async {
    if (!await _connectivity.hasConnection) return;

    try {
      // Upload pending changes
      final pendingExpenses = await _db.getPendingExpenses();
      for (final expense in pendingExpenses) {
        await _api.createExpense(expense);
        await _db.markAsSynced(expense.id);
      }

      // Download latest changes
      final remoteExpenses = await _api.getExpenses();
      await _db.mergeChnges(remoteExpenses);
    } catch (e) {
      LoggingService.logError('Sync failed', e);
    }
  }
}

/* 
===================================== 
PERFORMANCE OPTIMIZATIONS
===================================== 
*/

// 1. LAZY LOADING
class LazyExpenseList extends StatefulWidget {
  @override
  State<LazyExpenseList> createState() => _LazyExpenseListState();
}

class _LazyExpenseListState extends State<LazyExpenseList> {
  final ScrollController _scrollController = ScrollController();
  final ExpenseRepository _repository = GetIt.instance<ExpenseRepository>();
  List<Expense> _expenses = [];
  bool _isLoading = false;
  int _currentPage = 0;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final newExpenses = await _repository.getExpenses(
        page: _currentPage + 1,
        limit: _pageSize,
      );
      setState(() {
        _expenses.addAll(newExpenses);
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }
}

// 2. IMAGE OPTIMIZATION
class OptimizedImage extends StatelessWidget {
  final String url;
  final double width;
  final double height;

  const OptimizedImage({
    Key? key,
    required this.url,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      memCacheWidth: (width * MediaQuery.of(context).devicePixelRatio).round(),
      memCacheHeight: (height * MediaQuery.of(context).devicePixelRatio).round(),
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: width,
          height: height,
          color: Colors.white,
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Icon(Icons.error),
      ),
    );
  }
}

// 3. DATABASE OPTIMIZATION
class OptimizedDatabaseHelper extends DatabaseHelper {
  @override
  Future<List<Expense>> getExpenses({
    int? limit,
    int? offset,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    
    String query = '''
      SELECT * FROM expenses 
      WHERE 1=1
    ''';
    List<dynamic> args = [];

    if (category != null && category != 'All') {
      query += ' AND category = ?';
      args.add(category);
    }

    if (startDate != null) {
      query += ' AND date >= ?';
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      query += ' AND date <= ?';
      args.add(endDate.toIso8601String());
    }

    query += ' ORDER BY date DESC';

    if (limit != null) {
      query += ' LIMIT ?';
      args.add(limit);
      
      if (offset != null) {
        query += ' OFFSET ?';
        args.add(offset);
      }
    }

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, args);
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  // Add database indexes for better performance
  Future<void> _createIndexes() async {
    final db = await database;
    await db.execute('CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_expenses_amount ON expenses(amount)');
  }
}

/* 
===================================== 
TESTING IMPROVEMENTS
===================================== 
*/

// 1. Unit Tests
class MockExpenseRepository extends Mock implements ExpenseRepository {}

void main() {
  group('ExpenseBloc', () {
    late ExpenseBloc bloc;
    late MockExpenseRepository mockRepository;

    setUp(() {
      mockRepository = MockExpenseRepository();
      bloc = ExpenseBloc(mockRepository);
    });

    test('should emit ExpenseLoaded when LoadExpenses is added', () async {
      // Arrange
      final expenses = [Expense(/* ... */)];
      when(mockRepository.getAllExpenses()).thenAnswer((_) async => expenses);

      // Act
      bloc.add(LoadExpenses());

      // Assert
      await expectLater(
        bloc.stream,
        emitsInOrder([ExpenseLoading(), ExpenseLoaded(expenses)]),
      );
    });
  });
}

// 2. Widget Tests
void main() {
  testWidgets('ExpenseCard displays expense information correctly', (tester) async {
    // Arrange
    final expense = Expense(
      id: '1',
      title: 'Test Expense',
      amount: 100.0,
      category: 'food',
      date: DateTime.now(),
    );

    // Act
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ExpenseCard(expense: expense)),
    ));

    // Assert
    expect(find.text('Test Expense'), findsOneWidget);
    expect(find.text('100.0'), findsOneWidget);
  });
}

// 3. Integration Tests
void main() {
  group('App Integration Tests', () {
    testWidgets('should add expense and display in list', (tester) async {
      // Full app integration test
      await tester.pumpWidget(const MyApp());
      
      // Navigate to add expense
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      
      // Fill form
      await tester.enterText(find.byKey(const Key('title_field')), 'Test Expense');
      await tester.enterText(find.byKey(const Key('amount_field')), '100');
      
      // Submit
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      
      // Verify
      expect(find.text('Test Expense'), findsOneWidget);
    });
  });
}