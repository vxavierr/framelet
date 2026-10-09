#include "translator.hpp"
#include <QDirIterator>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QSet>
#include <QTest>

// Every string marked for translation needs a Portuguese entry with the same
// placeholders. A new qsTr()/tr() without one fails here, not in front of
// someone using the app.
class I18nTest : public QObject {
  Q_OBJECT
  static QString unescape(QString s) {
    s.replace("\\\"", "\"").replace("\\n", "\n").replace("\\\\", "\\");
    return s;
  }
  static QSet<QString> marked() {
    QSet<QString> keys;
    const QString root = QStringLiteral(FRAMELET_SOURCE_DIR);
    // qsTr("source") or qsTr("source", "disambiguation"). Plain literals:
    // moc stops parsing this file at raw strings that contain quotes.
    const QString text = QStringLiteral("\"((?:[^\"\\\\]|\\\\.)*)\"");
    const QRegularExpression qml("\\bqsTr\\(\\s*" + text + "\\s*(?:,\\s*" + text + "\\s*)?\\)");
    const QRegularExpression cpp("(?<![\\w:])tr\\(\\s*" + text + "\\s*\\)");
    for (const auto &[folder, pattern, expression] :
         {std::tuple{root + "/qml", QStringLiteral("*.qml"), qml},
          std::tuple{root + "/src", QStringLiteral("*.cpp"), cpp}}) {
      QDirIterator files(folder, {pattern}, QDir::Files);
      while (files.hasNext()) {
        QFile file(files.next());
        if (!file.open(QIODevice::ReadOnly))
          continue;
        auto matches = expression.globalMatch(QString::fromUtf8(file.readAll()));
        while (matches.hasNext()) {
          const auto match = matches.next();
          const QString key = unescape(match.captured(1));
          keys.insert(match.captured(2).isEmpty() ? key : key + '|' + match.captured(2));
        }
      }
    }
    return keys;
  }
  static QJsonObject portuguese() {
    QFile file(QStringLiteral(FRAMELET_SOURCE_DIR "/i18n/pt_BR.json"));
    if (!file.open(QIODevice::ReadOnly))
      return {};
    return QJsonDocument::fromJson(file.readAll()).object();
  }
  static QStringList placeholders(const QString &text) {
    QStringList found;
    auto matches = QRegularExpression("%\\d").globalMatch(text);
    while (matches.hasNext())
      found << matches.next().captured();
    found.sort();
    return found;
  }
private slots:
  void everyMarkedStringHasATranslation() {
    const auto keys = marked();
    QVERIFY(keys.size() > 150);
    const auto table = portuguese();
    QStringList missing;
    for (const auto &key : keys)
      if (table.value(key).toString().isEmpty())
        missing << key;
    missing.sort();
    QVERIFY2(missing.isEmpty(), qPrintable("Missing pt_BR: " + missing.join(" | ")));
  }
  void translationsKeepPlaceholders() {
    const auto table = portuguese();
    QStringList broken;
    for (auto it = table.constBegin(); it != table.constEnd(); ++it)
      if (placeholders(it.key()) != placeholders(it.value().toString()))
        broken << it.key();
    QVERIFY2(broken.isEmpty(), qPrintable(broken.join(" | ")));
  }
  void languageChoice() {
    QCOMPARE(JsonTranslator::languageFor("system", {"pt-BR", "en-US"}), QString("pt_BR"));
    QCOMPARE(JsonTranslator::languageFor("", {"en-US", "pt-BR"}), QString());
    QCOMPARE(JsonTranslator::languageFor("en", {"pt-BR"}), QString());
    QCOMPARE(JsonTranslator::languageFor("pt_BR", {"en-US"}), QString("pt_BR"));
    QCOMPARE(JsonTranslator::languageFor("de", {"pt-BR"}), QString());
  }
  void translatorFallsBackToEnglish() {
    JsonTranslator translator;
    QVERIFY(translator.loadJson(QStringLiteral(FRAMELET_SOURCE_DIR "/i18n/pt_BR.json")));
    QCOMPARE(translator.translate("InlineCapture", "Copy"), QString("Copiar"));
    QVERIFY(translator.translate("InlineCapture", "No such source string").isNull());
    QCOMPARE(translator.translate("HistoryPane", "Open"), QString("Abrir"));
    QCOMPARE(translator.translate("ToolStyleButton", "Open", "arrowhead"), QString("Aberta"));
    QCOMPARE(translator.translate("ToolStyleButton", "Filled", "arrowhead"), QString("Preenchida"));
  }
};
QTEST_GUILESS_MAIN(I18nTest)
#include "i18n-test.moc"
