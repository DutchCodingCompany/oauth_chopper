import 'package:oauth_chopper/src/storage/memory_storage.dart';
import 'package:test/test.dart';

void main() {
  test('Store & read a value', () async {
    // arrange
    final storage = MemoryStorage();

    // act
    storage.saveCredentials('test');
    final result = await storage.fetchCredentials();

    // assert
    expect(result, 'test');
  });

  test('Store, update & read a value', () async {
    // arrange
    final storage = MemoryStorage();

    // act
    storage.saveCredentials('test');
    final result1 = await storage.fetchCredentials();
    storage.saveCredentials('test2');
    final result2 = await storage.fetchCredentials();

    // assert
    expect(result1, 'test');
    expect(result2, 'test2');
  });

  test('Store, clear, store & read a value', () async {
    // arrange
    final storage = MemoryStorage();

    // act
    storage.saveCredentials('test');
    await storage.clear();
    storage.saveCredentials('test2');
    final result = await storage.fetchCredentials();

    // assert
    expect(result, 'test2');
  });

  test('Store, clear & read a value', () async {
    // arrange
    final storage = MemoryStorage();

    // act
    storage.saveCredentials('test');
    await storage.clear();
    final result = await storage.fetchCredentials();

    // assert
    expect(result, null);
  });

  test('Read a value', () async {
    // arrange
    final storage = MemoryStorage();

    // act
    final result = await storage.fetchCredentials();

    // assert
    expect(result, null);
  });
}
