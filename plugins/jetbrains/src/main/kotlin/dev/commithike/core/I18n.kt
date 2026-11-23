// Plugin texts (notifications, dialogs, the status bar). The language follows
// the core's setting (Commit Hike menu → Language), else the IDE's language.
// Menu item names in plugin.xml stay English: the platform reads them once.
// The texts come from i18n.json, generated from i18n/<lang>.json.
package dev.commithike.core

import com.google.gson.Gson

object I18n {
    /** How a language writes a distance: the decimal separator and the units. */
    data class Units(val decimal: String = ".", val m: String = "m", val km: String = "km")

    private class Meta(val name: String = "", val decimal: String = ".", val m: String = "m", val km: String = "km")

    private class Language(val meta: Meta = Meta(), val texts: Map<String, String> = emptyMap())

    private class Catalog(val order: List<String> = emptyList(), val languages: Map<String, Language> = emptyMap())

    private val catalog: Catalog = I18n::class.java.getResourceAsStream("/i18n.json")
        ?.reader(Charsets.UTF_8)
        ?.use { Gson().fromJson(it, Catalog::class.java) }
        ?: Catalog()

    private val catalogs: Map<String, Map<String, String>> = catalog.languages.mapValues { it.value.texts }
    private val en: Map<String, String> = catalogs["en"].orEmpty()

    /** The languages in the order of the language picker: English first, then by code. */
    val languages: List<String> = catalog.order
    val languageNames: Map<String, String> = catalog.languages.mapValues { it.value.meta.name }

    fun units(lang: String): Units {
        val meta = catalog.languages[lang]?.meta ?: return Units()
        return Units(meta.decimal, meta.m, meta.km)
    }

    @Volatile var lang: String = "en"
        private set

    fun setLanguage(tag: String?) {
        val base = (tag ?: "en").lowercase().split('-', '_').first()
        lang = if (catalogs.containsKey(base)) base else "en"
    }

    fun t(key: String, vararg args: Any): String {
        var s = catalogs[lang]?.get(key) ?: en[key] ?: key
        args.forEachIndexed { i, a -> s = s.replace("{$i}", a.toString()) }
        return s
    }

    /** Keys missing from a translation; used by tests. */
    fun missing(): Map<String, Set<String>> = catalogs.mapValues { (_, c) -> en.keys - c.keys }.filterValues { it.isNotEmpty() }

    fun distance(m: Double) = formatDistance(m, lang)

    /** A typical day of commits per level (mirrors score.TypicalDay in the core). */
    fun levelLabel(level: String): String {
        val factor = mapOf("easy" to 1.25, "medium" to 1.0, "hard" to 0.8)[level] ?: 1.0
        return t("diff.$level", distance(TYPICAL_MEDIUM_DAY_M * factor))
    }

    private const val TYPICAL_MEDIUM_DAY_M = 9851.4
}
