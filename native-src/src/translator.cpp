#include "translator.hpp"
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>

bool JsonTranslator::loadJson(const QString &path) {
  QFile file(path);
  if (!file.open(QIODevice::ReadOnly))
    return false;
  const auto document = QJsonDocument::fromJson(file.readAll());
  if (!document.isObject())
    return false;
  m_strings.clear();
  const auto object = document.object();
  for (auto it = object.constBegin(); it != object.constEnd(); ++it)
    if (it.value().isString() && !it.value().toString().isEmpty())
      m_strings.insert(it.key(), it.value().toString());
  return !m_strings.isEmpty();
}

QString JsonTranslator::translate(const char *, const char *sourceText,
                                  const char *disambiguation, int) const {
  // "Open|arrowhead" tells apart words that read differently in Portuguese.
  // A null result tells Qt to keep the English source.
  const QString source = QString::fromUtf8(sourceText);
  if (disambiguation && *disambiguation) {
    const QString specific =
        m_strings.value(source + '|' + QString::fromUtf8(disambiguation));
    if (!specific.isNull())
      return specific;
  }
  return m_strings.value(source);
}

QString JsonTranslator::languageFor(const QString &setting,
                                    const QStringList &uiLanguages) {
  const QString chosen = setting.trimmed();
  if (chosen.startsWith("pt", Qt::CaseInsensitive))
    return "pt_BR";
  if (!chosen.isEmpty() && chosen != "system")
    return {};
  for (const auto &language : uiLanguages) {
    if (language.startsWith("pt", Qt::CaseInsensitive))
      return "pt_BR";
    if (language.startsWith("en", Qt::CaseInsensitive))
      return {};
  }
  return {};
}
