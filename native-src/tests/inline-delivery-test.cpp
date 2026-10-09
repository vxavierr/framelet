#include "studio.hpp"
#include <QGuiApplication>
#include <QTemporaryDir>
#include <QSignalSpy>
#include <QTest>
#include <QFile>
#include <QDir>
#include <QStandardPaths>
#include <QSettings>
#include <QRegularExpression>
#include <QFileInfo>
#include <QDateTime>
class InlineDeliveryTest : public QObject {
  Q_OBJECT
private slots:
  void atelierPalettesAndFinishesPersist() {
    QSettings().remove("palettes");
    ImageStore store; Studio studio(&store,false);
    QCOMPARE(studio.palettes().size(),3);
    QVERIFY(!studio.savePalette("Broken",{"no-color","#ffffff","#000000","#ff0000","#00ff00"}));
    QVERIFY(!studio.savePalette("Atelier",{"#ffffff","#000000","#ff0000","#00ff00","#0000ff"}));
    QVERIFY(studio.savePalette("My inks",{"#102030","#ffffff","#ff0000","#00ff00","#0000ff"}));
    Studio reopened(&store,false);QCOMPARE(reopened.palettes().size(),4);
    for (const auto &name:QStringList{"Sketchbook","Ink","Gallery"}) {
      studio.applyFinish(name);studio.saveLook("Atelier proof");
      studio.applyFinish("Original");QVERIFY(!studio.framing().value("custom").toBool());
      studio.applyLook("Atelier proof");QCOMPARE(studio.framing().value("finishName").toString(),name);
      QCOMPARE(studio.framing().value("paper").toDouble(),name=="Sketchbook"?.65:0.);
      QCOMPARE(studio.framing().value("mat").toBool(),name=="Gallery");
    }
    studio.applyFinish("Original");
  }
  void sketchbookSaveMatchesPreviewAndKeepsCapturePixels() {
    QTemporaryDir folder;ImageStore store;Studio studio(&store,false);
    studio.setOutputDirectory(QUrl::fromLocalFile(folder.path()));
    QImage source(300,200,QImage::Format_RGB32);source.fill(QColor("#456789"));
    studio.scrollFinished(source,false,true);studio.applyFinish("Sketchbook");
    studio.configureFraming({{"exportScale",1}});studio.configureFraming({{"exportFormat","png"}});
    QTRY_VERIFY_WITH_TIMEOUT(!studio.rendering(),5000);
    const QImage preview=store.requestImage("preview",nullptr,{});
    QVERIFY(!preview.isNull());
    QSignalSpy done(&studio,&Studio::dismissRequested);studio.deliverInline(true);
    QTRY_COMPARE_WITH_TIMEOUT(done.count(),1,5000);
    QImage saved(studio.savedPath());QCOMPARE(saved.convertToFormat(QImage::Format_RGB32),preview.convertToFormat(QImage::Format_RGB32));
    QCOMPARE(saved.pixelColor(saved.width()/2,saved.height()/2),QColor("#456789"));
    studio.applyFinish("Original");
  }
  void savePreservesPixelsAndMarksWithoutClipboard() {
    QTemporaryDir folder; QVERIFY(folder.isValid());
    ImageStore store; Studio studio(&store, false);
    studio.setStyle(8);studio.configureFraming({{"custom",false},{"exportFormat","png"},{"exportScale",1}});
    studio.setOutputDirectory(QUrl::fromLocalFile(folder.path()));
    QImage source(300,200,QImage::Format_RGB32); source.fill(Qt::white);
    studio.scrollFinished(source,false,true);
    QTRY_VERIFY_WITH_TIMEOUT(!studio.rendering(),5000);
    studio.marks()->edit("arrow",0.1,0.2,0.8,0.8);
    QTRY_VERIFY_WITH_TIMEOUT(!studio.rendering(),5000);
    QSignalSpy finished(&studio,&Studio::dismissRequested);
    studio.deliverInline(true);
    QTRY_COMPARE_WITH_TIMEOUT(finished.count(),1,5000);
    const QImage saved(studio.savedPath());
    QCOMPARE(saved.size(),source.size());
    QCOMPARE(saved.convertToFormat(QImage::Format_RGB32),Frame::applyEdits(source,studio.marks()->edits()).convertToFormat(QImage::Format_RGB32));
    QCOMPARE(QDir(folder.path()).entryList({"*.png"},QDir::Files).size(),1);
  }
  void saveNamesByTimeAndCopiesThePath() {
    QTemporaryDir folder; QVERIFY(folder.isValid());
    const QString copied=folder.path()+"/clipboard.txt";
    qputenv("INLINE_COPY_DEST",copied.toUtf8());
    ImageStore store; Studio studio(&store,false);
    studio.setStyle(8);studio.configureFraming({{"custom",false},{"exportFormat","png"},{"exportScale",1}});
    studio.setOutputDirectory(QUrl::fromLocalFile(folder.path()));
    QImage source(120,80,QImage::Format_RGB32);source.fill(Qt::red);
    studio.scrollFinished(source,false,true);
    QTRY_VERIFY_WITH_TIMEOUT(!studio.rendering(),5000);
    QSignalSpy finished(&studio,&Studio::dismissRequested);
    studio.deliverInline(true);
    QTRY_COMPARE_WITH_TIMEOUT(finished.count(),1,5000);
    const QString saved=studio.savedPath();
    QVERIFY2(QRegularExpression("/Framelet-\\d{4}-\\d{2}-\\d{2}_\\d{2}-\\d{2}-\\d{2}(-\\d+)?\\.png$").match(saved).hasMatch(),qPrintable(saved));
    QVERIFY(QFileInfo(saved).isAbsolute() && QFile::exists(saved));
    QFile clip(copied);QVERIFY(clip.open(QIODevice::ReadOnly));
    QCOMPARE(QString::fromUtf8(clip.readAll()),saved);
    QCOMPARE(studio.status(),QString("Image saved. Its path is on the clipboard."));
    // A second save in the same second gets a numbered name, never an overwrite.
    const QDateTime when(QDate(2026,10,9),QTime(14,2,11));
    const QString first=Studio::capturePath(folder.path(),"png",when);
    QCOMPARE(QFileInfo(first).fileName(),QString("Framelet-2026-10-09_14-02-11.png"));
    QFile taken(first);QVERIFY(taken.open(QIODevice::WriteOnly));taken.close();
    QCOMPARE(QFileInfo(Studio::capturePath(folder.path(),"png",when)).fileName(),QString("Framelet-2026-10-09_14-02-11-2.png"));
    QCOMPARE(QFileInfo(Studio::capturePath(folder.path(),"jpg",when)).fileName(),QString("Framelet-2026-10-09_14-02-11.jpg"));
    // Turning the preference off leaves the clipboard alone.
    QFile::remove(copied);QSettings().setValue("copySavedPath",false);
    studio.scrollFinished(source,false,true);
    QTRY_VERIFY_WITH_TIMEOUT(!studio.rendering(),5000);
    studio.deliverInline(true);
    QTRY_COMPARE_WITH_TIMEOUT(finished.count(),2,5000);
    QVERIFY(!QFile::exists(copied));
    QCOMPARE(studio.status(),QString("Image saved."));
    QSettings().remove("copySavedPath");qunsetenv("INLINE_COPY_DEST");
  }
  void copyUsesTransientFileAndKeepsFailuresOpen() {
    QTemporaryDir folder; QVERIFY(folder.isValid());
    const QByteArray oldPath=qgetenv("PATH");
    const QByteArray oldRuntime=qgetenv("XDG_RUNTIME_DIR");
    qputenv("PATH",folder.path().toUtf8()+":"+oldPath);
    qputenv("XDG_RUNTIME_DIR",folder.path().toUtf8());
    const QString copied=folder.path()+"/copied.png";
    qputenv("INLINE_COPY_DEST",copied.toUtf8());
    QFile stub(folder.path()+"/wl-copy"); QVERIFY(stub.open(QIODevice::WriteOnly));
    stub.write("#!/bin/sh\n/usr/bin/cat > \"$INLINE_COPY_DEST\"\n");stub.close();
    QVERIFY(stub.setPermissions(QFile::ReadOwner|QFile::WriteOwner|QFile::ExeOwner));
    ImageStore store; Studio studio(&store,false);
    studio.setStyle(8);studio.configureFraming({{"custom",false},{"exportFormat","png"},{"exportScale",1}});
    QImage source(200,300,QImage::Format_RGB32);source.fill(Qt::blue);
    studio.scrollFinished(source,false,true);
    QTRY_VERIFY_WITH_TIMEOUT(!studio.rendering(),5000);
    QSignalSpy finished(&studio,&Studio::dismissRequested);
    studio.deliverInline(false);
    QTRY_COMPARE_WITH_TIMEOUT(finished.count(),1,5000);
    QCOMPARE(QImage(copied).convertToFormat(QImage::Format_RGB32),source);
    QVERIFY(studio.savedPath().isEmpty());
    QVERIFY(QDir(folder.path()+"/framelet").entryList({"*.png"},QDir::Files).isEmpty());
    QVERIFY(stub.open(QIODevice::WriteOnly|QIODevice::Truncate));stub.write("#!/bin/sh\nexit 1\n");stub.close();
    studio.deliverInline(false);
    QTRY_VERIFY_WITH_TIMEOUT(!studio.busy(),5000);
    QCOMPARE(finished.count(),1);
    QCOMPARE(studio.quickState(),QString("failed"));
    QVERIFY(studio.hasImage());
    qputenv("PATH",oldPath);qputenv("XDG_RUNTIME_DIR",oldRuntime);qunsetenv("INLINE_COPY_DEST");
  }
  void customLookSurvivesPresetAndExportsTransparency() {
    QTemporaryDir folder;ImageStore store;Studio studio(&store,false);
    studio.setOutputDirectory(QUrl::fromLocalFile(folder.path()));
    QImage source(300,200,QImage::Format_RGB32);source.fill(Qt::blue);
    studio.scrollFinished(source,false,true);studio.setStyle(8);
    studio.configureFraming({{"exportFormat","png"},{"exportScale",1},{"custom",true},{"backgroundMode","transparent"},{"corners",0.06},{"shadow",0.0},{"inset",0.04},{"titlebar",true},{"title","Minha captura"}});
    studio.saveLook("Transparente de teste");
    studio.configureFraming({{"backgroundMode","solid"},{"shadow",1.0}});
    studio.applyLook("Transparente de teste");
    QCOMPARE(studio.framing().value("backgroundMode").toString(),QString("transparent"));
    QCOMPARE(studio.framing().value("shadow").toDouble(),0.0);
    QVERIFY(studio.lookNames().contains("Transparente de teste"));
    QTRY_VERIFY_WITH_TIMEOUT(!studio.rendering(),5000);
    QSignalSpy done(&studio,&Studio::dismissRequested);studio.deliverInline(true);
    QTRY_COMPARE_WITH_TIMEOUT(done.count(),1,5000);
    QImage output(studio.savedPath());QVERIFY(output.width()>300 && output.height()>236);
    QCOMPARE(output.pixelColor(0,0).alpha(),0);
    QCOMPARE(studio.outputDimensions(),QString("%1 × %2").arg(output.width()).arg(output.height()));
  }
  void jpegExportScalesAndFlattensAlpha() {
    QTemporaryDir folder;ImageStore store;Studio studio(&store,false);
    studio.setOutputDirectory(QUrl::fromLocalFile(folder.path()));
    QImage source(200,100,QImage::Format_ARGB32_Premultiplied);source.fill(Qt::transparent);
    studio.scrollFinished(source,false,true);studio.setStyle(8);
    studio.configureFraming({{"custom",false},{"exportFormat","jpeg"},{"exportScale",2}});
    QTRY_VERIFY_WITH_TIMEOUT(!studio.rendering(),5000);
    QSignalSpy done(&studio,&Studio::dismissRequested);studio.deliverInline(true);
    QTRY_COMPARE_WITH_TIMEOUT(done.count(),1,5000);
    QVERIFY(studio.savedPath().endsWith(".jpg"));QImage output(studio.savedPath());
    QCOMPARE(output.size(),QSize(400,200));QVERIFY(!output.hasAlphaChannel());
    QVERIFY(output.pixelColor(10,10).red()>250);
  }
  void codeCardExportsHighlightedText() {
    QTemporaryDir folder;ImageStore store;Studio studio(&store,false);
    studio.setStyle(8);studio.configureFraming({{"custom",false},{"exportFormat","png"},{"exportScale",1}});
    studio.setOutputDirectory(QUrl::fromLocalFile(folder.path()));
    studio.makeCodeCard("const answer = 42;\nconsole.log(answer);", "javascript",16,true);
    QTRY_VERIFY_WITH_TIMEOUT(studio.hasImage() && !studio.busy() && !studio.rendering(),10000);
    QVERIFY(studio.sourceSize().width()>100 && studio.sourceSize().height()>50);
    QSignalSpy done(&studio,&Studio::dismissRequested);studio.deliverInline(true);
    QTRY_COMPARE_WITH_TIMEOUT(done.count(),1,5000);
    QImage output(studio.savedPath());QCOMPARE(output.size(),studio.sourceSize());
    int colored=0;
    for(int y=0;y<output.height();++y)for(int x=0;x<output.width();++x) {
      QColor c=output.pixelColor(x,y);if(c.red()>70 && qAbs(c.red()-c.blue())>30)++colored;
    }
    QVERIFY(colored>20);
  }
  void compositionKeepsExistingMarksAndAddsSecondImage() {
    QTemporaryDir folder;ImageStore store;Studio studio(&store,false);
    QImage source(300,200,QImage::Format_RGB32);source.fill(Qt::white);
    QImage second(50,100,QImage::Format_RGB32);second.fill(Qt::blue);
    const QString file=folder.path()+"/second.png";QVERIFY(second.save(file));
    studio.scrollFinished(source,false,true);studio.setStyle(8);studio.configureFraming({{"custom",false},{"exportFormat","png"},{"exportScale",1}});
    studio.marks()->edit("box",0.1,0.1,0.4,0.4);
    studio.addImage(QUrl::fromLocalFile(file),false);
    QCOMPARE(studio.sourceSize(),QSize(374,200));
    studio.setOutputDirectory(QUrl::fromLocalFile(folder.path()));
    QTRY_VERIFY_WITH_TIMEOUT(!studio.rendering(),5000);
    QSignalSpy done(&studio,&Studio::dismissRequested);studio.deliverInline(true);
    QTRY_COMPARE_WITH_TIMEOUT(done.count(),1,5000);
    QImage output(studio.savedPath());QCOMPARE(output.size(),QSize(374,200));
    QCOMPARE(output.pixelColor(330,20),QColor(Qt::blue));
    QVERIFY(output.pixelColor(30,40).red()>output.pixelColor(30,40).blue());
  }
};
int main(int argc,char**argv) {
  QGuiApplication app(argc,argv);QCoreApplication::setOrganizationName("CapturaInlineTests");
  QStandardPaths::setTestModeEnabled(true);
  // Saving copies the file's path. No case may reach the desktop clipboard,
  // so a stand-in wl-copy writes to INLINE_COPY_DEST or discards the data.
  QTemporaryDir stubs;if(!stubs.isValid())return 1;
  QFile stub(stubs.path()+"/wl-copy");if(!stub.open(QIODevice::WriteOnly))return 1;
  stub.write("#!/bin/sh\nif [ -n \"$INLINE_COPY_DEST\" ]; then /usr/bin/cat > \"$INLINE_COPY_DEST\"; else /usr/bin/cat > /dev/null; fi\n");stub.close();
  stub.setPermissions(QFile::ReadOwner|QFile::WriteOwner|QFile::ExeOwner);
  qputenv("PATH",stubs.path().toUtf8()+":"+qgetenv("PATH"));
  InlineDeliveryTest test;return QTest::qExec(&test,argc,argv);
}
#include "inline-delivery-test.moc"
