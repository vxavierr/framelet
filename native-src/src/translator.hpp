#pragma once
#include <QHash>
#include <QStringList>
#include <QTranslator>

// Translations without Qt's Linguist tools: a JSON object maps each English
// source string to its translation. The context is ignored on purpose, so a
// label reads the same on every Framelet surface.
class JsonTranslator : public QTranslator {
public:
  bool loadJson(const QString &path);
  bool isEmpty() const override { return m_strings.isEmpty(); }
  QString translate(const char *context, const char *sourceText,
                    const char *disambiguation = nullptr,
                    int n = -1) const override;
  /** The translation file to use, or empty for English. The setting is
   * "system", "en" or a language such as "pt_BR". */
  static QString languageFor(const QString &setting,
                             const QStringList &uiLanguages);

private:
  QHash<QString, QString> m_strings;
};
