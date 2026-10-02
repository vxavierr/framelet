#include <QFile>
#include <QDirIterator>
#include <QQmlComponent>
#include <QQmlEngine>
#include <QQuickItem>
#include <QTest>
#include <QRegularExpression>
#include <QNetworkAccessManager>
#include <QQmlNetworkAccessManagerFactory>

class OfflineFactory : public QQmlNetworkAccessManagerFactory {
public:
  int requests = 0;
  class Manager : public QNetworkAccessManager {
  public:
    OfflineFactory *owner;
    Manager(OfflineFactory *factory, QObject *parent) : QNetworkAccessManager(parent), owner(factory) {}
    QNetworkReply *createRequest(Operation, const QNetworkRequest &, QIODevice *) override {
      ++owner->requests;
      return nullptr; // Never issue an external request, even if the regression fails.
    }
  };
  QNetworkAccessManager *create(QObject *parent) override { return new Manager(this, parent); }
};

class LiteralTextTest : public QObject {
  Q_OBJECT
private slots:
  void displayPolicy() {
    QDirIterator files(QStringLiteral(QML_SOURCE_DIR), {"*.qml"}, QDir::Files);
    int count = 0;
    while (files.hasNext()) {
      QFile file(files.next());
      QVERIFY(file.open(QIODevice::ReadOnly));
      const QString source = QString::fromUtf8(file.readAll());
      auto tooltips = QRegularExpression(R"(ToolTip\.text:\s*([^\n]+))").globalMatch(source);
      while (tooltips.hasNext()) {
        const auto tooltip = tooltips.next();
        QVERIFY2(tooltip.captured(1).trimmed().startsWith('"'), qPrintable(file.fileName()));
      }
      auto matches = QRegularExpression(R"(\bText\s*\{\s*([^;\n]*))").globalMatch(source);
      while (matches.hasNext()) {
        ++count;
        const auto match = matches.next();
        QVERIFY2(match.captured(1).contains("textFormat: Text.PlainText"), qPrintable(file.fileName()));
      }
    }
    QVERIFY(count > 100);
  }
  void tooltipNamesAreLiteral() {
    OfflineFactory factory;
    QQmlEngine engine;
    engine.setNetworkAccessManagerFactory(&factory);
    QQmlComponent component(&engine, QUrl::fromLocalFile(QStringLiteral(QML_SOURCE_DIR "/LiteralToolTip.qml")));
    QScopedPointer<QObject> tooltip(component.create());
    QVERIFY2(tooltip, qPrintable(component.errorString()));
    QObject *label = tooltip->findChild<QObject*>("literalTooltipText");
    QVERIFY(label);
    const QString value = "Saved <img src=\"https://example.invalid/private.png\">.png";
    tooltip->setProperty("text", value);
    QCOMPARE(label->property("text").toString(), value);
    QCOMPARE(label->property("textFormat").toInt(), 0);
    QCoreApplication::processEvents();
    QCOMPARE(factory.requests, 0);
  }
  void annotationsAndNamesAreLiteral() {
    QFile file(QStringLiteral(QML_SOURCE_DIR "/MarkCanvas.qml"));
    QVERIFY(file.open(QIODevice::ReadOnly));
    const QString source = QString::fromUtf8(file.readAll());
    auto match = QRegularExpression(R"(Text\s*\{[^{}]*id: measure[^{}]*\})").match(source);
    QVERIFY(match.hasMatch());
    QString measure = match.captured().replace("font: field.font", "font.pixelSize: 16")
      .replace("field.text.length ? field.text : \" \"", "input.length ? input : \" \"");
    OfflineFactory factory;
    QQmlEngine engine;
    engine.setNetworkAccessManagerFactory(&factory);
    QQmlComponent component(&engine);
    component.setData(("import QtQuick\nItem { property string input; " + measure + " }").toUtf8(), QUrl());
    QScopedPointer<QObject> root(component.create());
    QVERIFY2(root, qPrintable(component.errorString()));
    QObject *label = root->findChild<QObject*>();
    // The measuring Text is the only child in this fixture.
    QVERIFY(label);
    const QStringList values = {"<b>literal annotation</b>", "<img src=\"https://example.invalid/private.png\">",
      "<b>photo</b>.png", "<img src=\"https://example.invalid/name.png\">.mp4", "A & B < C\nsecond line"};
    for (const QString &value : values) {
      root->setProperty("input", value);
      QCOMPARE(label->property("text").toString(), value);
      QCOMPARE(label->property("textFormat").toInt(), 0); // QQuickText::PlainText
      QVERIFY(label->property("implicitWidth").toDouble() > 0);
      QCoreApplication::processEvents();
    }
    QCOMPARE(factory.requests, 0);
  }
};
QTEST_MAIN(LiteralTextTest)
#include "literal-text-test.moc"
