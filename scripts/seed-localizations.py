#!/usr/bin/env python3
"""One-shot seeder: fills Localizable.xcstrings translations for the 6 non-source
languages (en, de, es, it, pt, ja) from the dictionary below. Keys absent from the
dictionary are left untranslated on purpose (they fall back to the French source):
proper nouns, sample/preview data, pure format specifiers, symbols and dev-only
admin labels. Run once after `xcstringstool sync`; the .xcstrings is the source of
truth afterwards. Order of languages in each tuple: en, de, es, it, pt, ja."""

import json
from pathlib import Path

CATALOG = Path("ios/Vinarium/Resources/Localizable.xcstrings")
LANGS = ["en", "de", "es", "it", "pt", "ja"]

# fr source -> (en, de, es, it, pt, ja)
T = {
    # --- Tabs / navigation ---
    "Accueil": ("Home", "Start", "Inicio", "Home", "Início", "ホーム"),
    "Cave": ("Cellar", "Weinkeller", "Bodega", "Cantina", "Adega", "セラー"),
    "Vins": ("Wines", "Weine", "Vinos", "Vini", "Vinhos", "ワイン"),
    "Scanner": ("Scan", "Scannen", "Escanear", "Scansiona", "Digitalizar", "スキャン"),
    "Réglages": ("Settings", "Einstellungen", "Ajustes", "Impostazioni", "Definições", "設定"),
    "Profil": ("Profile", "Profil", "Perfil", "Profilo", "Perfil", "プロフィール"),
    "Ma Cave": ("My Cellar", "Mein Weinkeller", "Mi bodega", "La mia cantina", "A minha adega", "マイセラー"),
    "Mes Vins": ("My Wines", "Meine Weine", "Mis vinos", "I miei vini", "Os meus vinhos", "マイワイン"),
    "Journal": ("Journal", "Verlauf", "Diario", "Diario", "Diário", "履歴"),
    "Détails": ("Details", "Details", "Detalles", "Dettagli", "Detalhes", "詳細"),

    # --- Common actions / buttons ---
    "Ajouter": ("Add", "Hinzufügen", "Añadir", "Aggiungi", "Adicionar", "追加"),
    "Annuler": ("Cancel", "Abbrechen", "Cancelar", "Annulla", "Cancelar", "キャンセル"),
    "Confirmer": ("Confirm", "Bestätigen", "Confirmar", "Conferma", "Confirmar", "確認"),
    "Enregistrer": ("Save", "Speichern", "Guardar", "Salva", "Guardar", "保存"),
    "Enregistrement…": ("Saving…", "Speichern…", "Guardando…", "Salvataggio…", "A guardar…", "保存中…"),
    "Modifier": ("Edit", "Bearbeiten", "Editar", "Modifica", "Editar", "編集"),
    "Supprimer": ("Delete", "Löschen", "Eliminar", "Elimina", "Eliminar", "削除"),
    "Fermer": ("Close", "Schließen", "Cerrar", "Chiudi", "Fechar", "閉じる"),
    "Continuer": ("Continue", "Weiter", "Continuar", "Continua", "Continuar", "続ける"),
    "Commencer": ("Get started", "Loslegen", "Empezar", "Inizia", "Começar", "始める"),
    "Terminer": ("Finish", "Fertig", "Terminar", "Fine", "Concluir", "完了"),
    "Terminé": ("Done", "Fertig", "Hecho", "Fatto", "Concluído", "完了"),
    "OK": ("OK", "OK", "OK", "OK", "OK", "OK"),
    "Réessayer": ("Try again", "Erneut versuchen", "Reintentar", "Riprova", "Tentar de novo", "再試行"),
    "Rétablir": ("Restore", "Wiederherstellen", "Restaurar", "Ripristina", "Restaurar", "復元"),
    "Remplacer": ("Replace", "Ersetzen", "Reemplazar", "Sostituisci", "Substituir", "置き換え"),
    "Exporter": ("Export", "Exportieren", "Exportar", "Esparta", "Exportar", "エクスポート"),
    "Importer": ("Import", "Importieren", "Importar", "Importa", "Importar", "インポート"),
    "Mettre à jour": ("Update", "Aktualisieren", "Actualizar", "Aggiorna", "Atualizar", "アップデート"),
    "Se déconnecter": ("Sign out", "Abmelden", "Cerrar sesión", "Disconnetti", "Terminar sessão", "サインアウト"),
    "Copier le lien": ("Copy link", "Link kopieren", "Copiar enlace", "Copia link", "Copiar ligação", "リンクをコピー"),
    "Lien copié": ("Link copied", "Link kopiert", "Enlace copiado", "Link copiato", "Ligação copiada", "リンクをコピーしました"),
    "Révoquer": ("Revoke", "Widerrufen", "Revocar", "Revoca", "Revogar", "取り消す"),
    "Ajuster": ("Adjust", "Anpassen", "Ajustar", "Regola", "Ajustar", "調整"),
    "Rechercher": ("Search", "Suchen", "Buscar", "Cerca", "Pesquisar", "検索"),
    "Recherche": ("Search", "Suche", "Búsqueda", "Ricerca", "Pesquisa", "検索"),
    "Consommer": ("Consume", "Trinken", "Consumir", "Consuma", "Consumir", "消費する"),
    "Déplacer": ("Move", "Verschieben", "Mover", "Sposta", "Mover", "移動"),
    "Sortir": ("Take out", "Entnehmen", "Sacar", "Estrai", "Retirar", "取り出す"),
    "Offrir": ("Give", "Verschenken", "Regalar", "Regala", "Oferecer", "贈る"),
    "Importer / Exporter": ("Import / Export", "Import / Export", "Importar / Exportar", "Importa / Esporta", "Importar / Exportar", "インポート / エクスポート"),

    # --- Empty states / placeholders ---
    "Chargement": ("Loading", "Wird geladen", "Cargando", "Caricamento", "A carregar", "読み込み中"),
    "Cave vide": ("Empty cellar", "Leerer Weinkeller", "Bodega vacía", "Cantina vuota", "Adega vazia", "セラーは空です"),
    "Ajoutez des bouteilles via le scanner": ("Add bottles with the scanner", "Flaschen über den Scanner hinzufügen", "Añade botellas con el escáner", "Aggiungi bottiglie con lo scanner", "Adicione garrafas com o scanner", "スキャナーでボトルを追加"),
    "Aucun historique": ("No history", "Kein Verlauf", "Sin historial", "Nessuno storico", "Sem histórico", "履歴なし"),
    "L'historique apparaîtra ici": ("History will appear here", "Der Verlauf erscheint hier", "El historial aparecerá aquí", "Lo storico apparirà qui", "O histórico aparecerá aqui", "履歴がここに表示されます"),
    "Aucun favori": ("No favorites", "Keine Favoriten", "Sin favoritos", "Nessun preferito", "Sem favoritos", "お気に入りなし"),
    "Ajoutez vos coups de cœur en favoris": ("Add your favorites here", "Füge deine Lieblingsweine zu den Favoriten hinzu", "Añade tus favoritos aquí", "Aggiungi i tuoi preferiti", "Adicione os seus favoritos", "お気に入りを追加"),
    "Aucun lieu": ("No place", "Kein Ort", "Sin lugar", "Nessun luogo", "Sem local", "場所なし"),
    "Aucun résultat": ("No results", "Keine Ergebnisse", "Sin resultados", "Nessun risultato", "Sem resultados", "結果なし"),
    "Aucun vin": ("No wine", "Kein Wein", "Sin vinos", "Nessun vino", "Sem vinho", "ワインなし"),
    "Aucun vin conseillé": ("No recommended wine", "Kein empfohlener Wein", "Sin vinos recomendados", "Nessun vino consigliato", "Sem vinhos recomendados", "おすすめワインなし"),
    "Aucun vin ne correspond à ce filtre": ("No wine matches this filter", "Kein Wein passt zu diesem Filter", "Ningún vino coincide con este filtro", "Nessun vino corrisponde a questo filtro", "Nenhum vinho corresponde a este filtro", "この絞り込みに該当するワインはありません"),
    "Aucun vin ne correspond à cette recherche.": ("No wine matches this search.", "Kein Wein passt zu dieser Suche.", "Ningún vino coincide con esta búsqueda.", "Nessun vino corrisponde a questa ricerca.", "Nenhum vinho corresponde a esta pesquisa.", "この検索に該当するワインはありません。"),
    "Aucun vin offert": ("No gifted wine", "Kein geschenkter Wein", "Sin vinos regalados", "Nessun vino regalato", "Sem vinhos oferecidos", "贈られたワインなし"),
    "Aucun vin prêt à déguster": ("No wine ready to drink", "Kein trinkfertiger Wein", "Sin vinos listos para beber", "Nessun vino pronto da bere", "Sem vinhos prontos a beber", "飲み頃のワインなし"),
    "Aucun événement récent": ("No recent activity", "Keine letzten Aktivitäten", "Sin actividad reciente", "Nessuna attività recente", "Sem atividade recente", "最近のアクティビティなし"),
    "Aucune entrée": ("No entry", "Kein Eintrag", "Sin entradas", "Nessuna voce", "Sem entradas", "エントリーなし"),
    "Aucune étiquette détectée": ("No label detected", "Kein Etikett erkannt", "No se detectó ninguna etiqueta", "Nessuna etichetta rilevata", "Nenhum rótulo detetado", "ラベルが検出されませんでした"),
    "Aucun code actif": ("No active code", "Kein aktiver Code", "Sin código activo", "Nessun codice attivo", "Sem código ativo", "有効なコードなし"),
    "Les vins conseillés par vos amis apparaîtront ici": ("Wines recommended by your friends will appear here", "Von deinen Freunden empfohlene Weine erscheinen hier", "Los vinos recomendados por tus amigos aparecerán aquí", "I vini consigliati dai tuoi amici appariranno qui", "Os vinhos recomendados pelos seus amigos aparecerão aqui", "友人がおすすめするワインがここに表示されます"),
    "Les vins qu'on vous a offerts apparaîtront ici": ("Wines you were given will appear here", "Dir geschenkte Weine erscheinen hier", "Los vinos que te han regalado aparecerán aquí", "I vini che ti sono stati regalati appariranno qui", "Os vinhos que lhe ofereceram aparecerão aqui", "贈られたワインがここに表示されます"),

    # --- Beverage types / colors / subtypes (wine terminology) ---
    "Vin": ("Wine", "Wein", "Vino", "Vino", "Vinho", "ワイン"),
    "Spiritueux": ("Spirit", "Spirituose", "Licor", "Distillato", "Destilado", "スピリッツ"),
    "Bière": ("Beer", "Bier", "Cerveza", "Birra", "Cerveja", "ビール"),
    "Saké": ("Sake", "Sake", "Sake", "Sake", "Saqué", "日本酒"),
    "Cidre": ("Cider", "Cidre", "Sidra", "Sidro", "Cidra", "シードル"),
    "Autre": ("Other", "Andere", "Otro", "Altro", "Outro", "その他"),
    "Rouge": ("Red", "Rot", "Tinto", "Rosso", "Tinto", "赤"),
    "Blanc": ("White", "Weiß", "Blanco", "Bianco", "Branco", "白"),
    "Rosé": ("Rosé", "Rosé", "Rosado", "Rosato", "Rosé", "ロゼ"),
    "Pétillant": ("Sparkling", "Schäumend", "Espumoso", "Frizzante", "Espumante", "スパークリング"),
    "Moelleux": ("Sweet", "Lieblich", "Dulce", "Dolce", "Meio-doce", "甘口"),
    "Vendanges tardives": ("Late harvest", "Spätlese", "Vendimia tardía", "Vendemmia tardiva", "Colheita tardia", "遅摘み"),
    "Vin jaune": ("Vin jaune", "Vin Jaune", "Vino amarillo", "Vin jaune", "Vinho amarelo", "ヴァン・ジョーヌ"),
    "Vin muté": ("Fortified wine", "Likörwein", "Vino generoso", "Vino fortificato", "Vinho fortificado", "酒精強化ワイン"),
    "Rhum": ("Rum", "Rum", "Ron", "Rum", "Rum", "ラム"),
    "Liqueur": ("Liqueur", "Likör", "Licor", "Liquore", "Licor", "リキュール"),
    "Eau-de-vie": ("Eau-de-vie", "Obstbrand", "Aguardiente", "Acquavite", "Aguardente", "オー・ド・ヴィー"),
    "Blonde": ("Blonde", "Hell", "Rubia", "Bionda", "Loura", "ブロンド"),
    "Blanche": ("Wheat", "Weizen", "Blanca", "Blanche", "Trigo", "ホワイト"),
    "Ambrée": ("Amber", "Bernstein", "Ámbar", "Ambrata", "Âmbar", "アンバー"),
    "Brune": ("Brown", "Dunkel", "Morena", "Bruna", "Escura", "ブラウン"),
    "Doux": ("Sweet", "Süß", "Dulce", "Dolce", "Doce", "甘口"),
    "Demi-sec": ("Semi-dry", "Halbtrocken", "Semiseco", "Semisecco", "Meio-seco", "やや辛口"),
    "Poiré": ("Perry", "Birnenmost", "Perada", "Sidro di pere", "Perada", "ペリー"),
    "Saké pétillant": ("Sparkling sake", "Schäumender Sake", "Sake espumoso", "Sake frizzante", "Saqué espumante", "スパークリング日本酒"),

    # --- Wine fields / details ---
    "Nom": ("Name", "Name", "Nombre", "Nome", "Nome", "名前"),
    "Prénom": ("First name", "Vorname", "Nombre", "Nome", "Nome próprio", "名前"),
    "Millésime": ("Vintage", "Jahrgang", "Añada", "Annata", "Colheita", "ヴィンテージ"),
    "Année": ("Year", "Jahr", "Año", "Anno", "Ano", "年"),
    "Région": ("Region", "Region", "Región", "Regione", "Região", "地域"),
    "Pays": ("Country", "Land", "País", "Paese", "País", "国"),
    "Couleur": ("Color", "Farbe", "Color", "Colore", "Cor", "色"),
    "Appellation": ("Appellation", "Appellation", "Denominación", "Denominazione", "Denominação", "アペラシオン"),
    "Classification": ("Classification", "Klassifizierung", "Clasificación", "Classificazione", "Classificação", "格付け"),
    "Cépages": ("Grape varieties", "Rebsorten", "Variedades de uva", "Vitigni", "Castas", "ブドウ品種"),
    "Degré": ("ABV", "Alkoholgehalt", "Graduación", "Gradazione", "Teor alcoólico", "アルコール度数"),
    "Prix": ("Price", "Preis", "Precio", "Prezzo", "Preço", "価格"),
    "Producteur": ("Producer", "Erzeuger", "Productor", "Produttore", "Produtor", "生産者"),
    "Domaine": ("Estate", "Weingut", "Bodega", "Tenuta", "Quinta", "ドメーヌ"),
    "Distillerie": ("Distillery", "Brennerei", "Destilería", "Distilleria", "Destilaria", "蒸溜所"),
    "Brasserie": ("Brewery", "Brauerei", "Cervecería", "Birrificio", "Cervejaria", "醸造所"),
    "Cidrerie": ("Cidery", "Cidrerie", "Sidrería", "Sidreria", "Cidraria", "シードル醸造所"),
    "Type": ("Type", "Typ", "Tipo", "Tipo", "Tipo", "種類"),
    "Sous-type": ("Subtype", "Untertyp", "Subtipo", "Sottotipo", "Subtipo", "サブタイプ"),
    "Statut": ("Status", "Status", "Estado", "Stato", "Estado", "ステータス"),
    "Origine": ("Origin", "Herkunft", "Origen", "Origine", "Origem", "産地"),
    "Note": ("Rating", "Bewertung", "Nota", "Voto", "Nota", "評価"),
    "Notes": ("Notes", "Notizen", "Notas", "Note", "Notas", "メモ"),
    "Commentaire": ("Comment", "Kommentar", "Comentario", "Commento", "Comentário", "コメント"),
    "Commentaires": ("Comments", "Kommentare", "Comentarios", "Commenti", "Comentários", "コメント"),
    "Date": ("Date", "Datum", "Fecha", "Data", "Data", "日付"),
    "Date d'achat": ("Purchase date", "Kaufdatum", "Fecha de compra", "Data d'acquisto", "Data de compra", "購入日"),
    "Date de modification": ("Last modified", "Änderungsdatum", "Fecha de modificación", "Data di modifica", "Data de modificação", "更新日"),
    "Position": ("Position", "Position", "Posición", "Posizione", "Posição", "位置"),
    "Placement": ("Placement", "Platzierung", "Ubicación", "Posizionamento", "Colocação", "配置"),
    "Informations principales": ("Main information", "Wichtigste Infos", "Información principal", "Informazioni principali", "Informações principais", "基本情報"),
    "Résumé": ("Summary", "Zusammenfassung", "Resumen", "Riepilogo", "Resumo", "概要"),
    "Récapitulatif": ("Overview", "Übersicht", "Resumen", "Riepilogo", "Resumo", "まとめ"),
    "Dégustation": ("Tasting", "Verkostung", "Cata", "Degustazione", "Degustação", "テイスティング"),
    "Vos impressions, arômes, accords...": ("Your impressions, aromas, pairings...", "Deine Eindrücke, Aromen, Kombinationen...", "Tus impresiones, aromas, maridajes...", "Le tue impressioni, aromi, abbinamenti...", "As suas impressões, aromas, harmonizações...", "感想、香り、ペアリング..."),

    # --- Statuses / cellar ---
    "En cave": ("In cellar", "Im Weinkeller", "En bodega", "In cantina", "Na adega", "セラー内"),
    "Consommé": ("Consumed", "Getrunken", "Consumido", "Consumato", "Consumido", "消費済み"),
    "Consommés": ("Consumed", "Getrunken", "Consumidos", "Consumati", "Consumidos", "消費済み"),
    "Consommé le": ("Consumed on", "Getrunken am", "Consumido el", "Consumato il", "Consumido em", "消費日"),
    "Entrée": ("In", "Eingang", "Entrada", "Entrata", "Entrada", "入庫"),
    "Entrée le": ("Added on", "Hinzugefügt am", "Añadido el", "Aggiunto il", "Adicionado em", "追加日"),
    "Sortie": ("Out", "Ausgang", "Salida", "Uscita", "Saída", "出庫"),
    "Sortie le": ("Removed on", "Entfernt am", "Retirado el", "Rimosso il", "Retirado em", "出庫日"),
    "Sortir de la cave": ("Take out of the cellar", "Aus dem Weinkeller nehmen", "Sacar de la bodega", "Estrai dalla cantina", "Retirar da adega", "セラーから取り出す"),
    "Prêt à déguster": ("Ready to drink", "Trinkreif", "Listo para beber", "Pronto da bere", "Pronto a beber", "飲み頃"),
    "À déguster rapidement": ("Drink soon", "Bald trinken", "Beber pronto", "Da bere presto", "Beber em breve", "早めに飲む"),
    "Garde": ("Cellaring", "Lagerung", "Guarda", "Invecchiamento", "Guarda", "熟成"),
    "Suggéré": ("Suggested", "Vorgeschlagen", "Sugerido", "Suggerito", "Sugerido", "おすすめ"),
    "Position : %@": ("Position: %@", "Position: %@", "Posición: %@", "Posizione: %@", "Posição: %@", "位置: %@"),
    "Rangée %@": ("Row %@", "Reihe %@", "Fila %@", "Fila %@", "Fila %@", "行 %@"),
    "Rangées": ("Rows", "Reihen", "Filas", "File", "Filas", "行"),
    "Actuellement en %@": ("Currently in %@", "Derzeit in %@", "Actualmente en %@", "Attualmente in %@", "Atualmente em %@", "現在 %@"),
    "Déplacer en %@ ?": ("Move to %@?", "Nach %@ verschieben?", "¿Mover a %@?", "Spostare in %@?", "Mover para %@?", "%@ に移動しますか？"),
    "Placer en %@ ?": ("Place in %@?", "In %@ platzieren?", "¿Colocar en %@?", "Posizionare in %@?", "Colocar em %@?", "%@ に配置しますか？"),
    "Échanger avec %@ (%@) ?": ("Swap with %@ (%@)?", "Mit %@ (%@) tauschen?", "¿Intercambiar con %@ (%@)?", "Scambiare con %@ (%@)?", "Trocar com %@ (%@)?", "%@（%@）と入れ替えますか？"),
    "Avant %@": ("Before %@", "Vor %@", "Antes de %@", "Prima del %@", "Antes de %@", "%@ より前"),
    "Consommé le %@": ("Consumed on %@", "Getrunken am %@", "Consumido el %@", "Consumato il %@", "Consumido em %@", "消費日 %@"),
    "À partir de": ("From", "Ab", "Desde", "Da", "A partir de", "から"),
    "Jusqu'à": ("Until", "Bis", "Hasta", "Fino a", "Até", "まで"),

    # --- Filters / sort ---
    "Tous": ("All", "Alle", "Todos", "Tutti", "Todos", "すべて"),
    "Toutes": ("All", "Alle", "Todas", "Tutte", "Todas", "すべて"),
    "Tri": ("Sort", "Sortieren", "Ordenar", "Ordina", "Ordenar", "並べ替え"),
    "Croissant": ("Ascending", "Aufsteigend", "Ascendente", "Crescente", "Crescente", "昇順"),
    "Décroissant": ("Descending", "Absteigend", "Descendente", "Decrescente", "Decrescente", "降順"),
    "Par personne": ("By person", "Nach Person", "Por persona", "Per persona", "Por pessoa", "人物別"),
    "Favoris": ("Favorites", "Favoriten", "Favoritos", "Preferiti", "Favoritos", "お気に入り"),
    "Favori": ("Favorite", "Favorit", "Favorito", "Preferito", "Favorito", "お気に入り"),
    "Mes favoris": ("My favorites", "Meine Favoriten", "Mis favoritos", "I miei preferiti", "Os meus favoritos", "マイお気に入り"),
    "Offerts": ("Gifted", "Geschenkt", "Regalados", "Regalati", "Oferecidos", "贈られた"),
    "Offert": ("Gifted", "Geschenkt", "Regalado", "Regalato", "Oferecido", "贈られた"),
    "Offert le": ("Gifted on", "Geschenkt am", "Regalado el", "Regalato il", "Oferecido em", "贈呈日"),
    "Offert par": ("Gifted by", "Geschenkt von", "Regalado por", "Regalato da", "Oferecido por", "贈り主"),
    "Conseillés": ("Recommended", "Empfohlen", "Recomendados", "Consigliati", "Recomendados", "おすすめ"),
    "Conseillé": ("Recommended", "Empfohlen", "Recomendado", "Consigliato", "Recomendado", "おすすめ"),
    "Conseillé par": ("Recommended by", "Empfohlen von", "Recomendado por", "Consigliato da", "Recomendado por", "推薦者"),
    "Conseillé par un ami": ("Recommended by a friend", "Von einem Freund empfohlen", "Recomendado por un amigo", "Consigliato da un amico", "Recomendado por um amigo", "友人からのおすすめ"),
    "Ajouter aux favoris": ("Add to favorites", "Zu Favoriten hinzufügen", "Añadir a favoritos", "Aggiungi ai preferiti", "Adicionar aos favoritos", "お気に入りに追加"),
    "Retirer des favoris": ("Remove from favorites", "Aus Favoriten entfernen", "Quitar de favoritos", "Rimuovi dai preferiti", "Remover dos favoritos", "お気に入りから削除"),
    "Vos coups de cœur": ("Your favorites", "Deine Lieblingsweine", "Tus favoritos", "I tuoi preferiti", "Os seus favoritos", "あなたのお気に入り"),

    # --- Search ---
    "Vin, producteur, personne…": ("Wine, producer, person…", "Wein, Erzeuger, Person…", "Vino, productor, persona…", "Vino, produttore, persona…", "Vinho, produtor, pessoa…", "ワイン、生産者、人物…"),
    "Un nom de vin, un producteur, un millésime ou une personne — ou affinez avec les filtres ci-dessus.": (
        "A wine name, a producer, a vintage or a person, or refine with the filters above.",
        "Ein Weinname, ein Erzeuger, ein Jahrgang oder eine Person, oder verfeinere mit den Filtern oben.",
        "Un nombre de vino, un productor, una añada o una persona, o afina con los filtros de arriba.",
        "Un nome di vino, un produttore, un'annata o una persona, oppure affina con i filtri qui sopra.",
        "Um nome de vinho, um produtor, uma colheita ou uma pessoa, ou refine com os filtros acima.",
        "ワイン名、生産者、ヴィンテージ、人物で検索、または上の絞り込みで調整。"),
    "Effacer la recherche": ("Clear search", "Suche löschen", "Borrar búsqueda", "Cancella ricerca", "Limpar pesquisa", "検索をクリア"),

    # --- Scan flow ---
    "Analyse": ("Analysis", "Analyse", "Análisis", "Analisi", "Análise", "解析"),
    "Analyse en cours": ("Analyzing", "Analyse läuft", "Analizando", "Analisi in corso", "A analisar", "解析中"),
    "Identification de l'étiquette...": ("Identifying the label...", "Etikett wird erkannt...", "Identificando la etiqueta...", "Identificazione dell'etichetta...", "A identificar o rótulo...", "ラベルを識別中..."),
    "L'IA n'a rien trouvé à identifier ici. Réessaie avec une photo plus nette.": (
        "The AI found nothing to identify here. Try again with a sharper photo.",
        "Die KI konnte hier nichts erkennen. Versuche es mit einem schärferen Foto.",
        "La IA no encontró nada que identificar aquí. Prueba con una foto más nítida.",
        "L'IA non ha trovato nulla da identificare. Riprova con una foto più nitida.",
        "A IA não encontrou nada para identificar aqui. Tente com uma foto mais nítida.",
        "AIは識別できるものを見つけられませんでした。より鮮明な写真で再試行してください。"),
    "Vérifier la bouteille": ("Check the bottle", "Flasche prüfen", "Verificar la botella", "Verifica la bottiglia", "Verificar a garrafa", "ボトルを確認"),
    "Ajouter cette bouteille": ("Add this bottle", "Diese Flasche hinzufügen", "Añadir esta botella", "Aggiungi questa bottiglia", "Adicionar esta garrafa", "このボトルを追加"),
    "Bouteille ajoutée avec succès": ("Bottle added successfully", "Flasche erfolgreich hinzugefügt", "Botella añadida correctamente", "Bottiglia aggiunta", "Garrafa adicionada com sucesso", "ボトルを追加しました"),
    "Ranger en cave": ("Store in the cellar", "Im Weinkeller einlagern", "Guardar en la bodega", "Riponi in cantina", "Guardar na adega", "セラーに収納"),
    "Juste enregistrer": ("Just save", "Nur speichern", "Solo guardar", "Salva soltanto", "Apenas guardar", "保存のみ"),
    "Que veux-tu en faire ?": ("What would you like to do with it?", "Was möchtest du damit tun?", "¿Qué quieres hacer con ella?", "Cosa vuoi farne?", "O que deseja fazer com ela?", "どうしますか？"),
    "Comment souhaitez-vous sortir ce vin ?": ("How would you like to take this wine out?", "Wie möchtest du diesen Wein entnehmen?", "¿Cómo quieres sacar este vino?", "Come vuoi estrarre questo vino?", "Como deseja retirar este vinho?", "このワインをどのように取り出しますか？"),
    "Succès !": ("Success!", "Erfolg!", "¡Listo!", "Fatto!", "Sucesso!", "完了！"),

    # --- Onboarding / profile ---
    "Bienvenue dans Vinarium": ("Welcome to Vinarium", "Willkommen bei Vinarium", "Bienvenido a Vinarium", "Benvenuto in Vinarium", "Bem-vindo ao Vinarium", "Vinariumへようこそ"),
    "Configurons votre cave en quelques étapes : votre prénom et les dimensions de votre cave.": (
        "Let's set up your cellar in a few steps: your first name and your cellar's dimensions.",
        "Richten wir deinen Weinkeller in wenigen Schritten ein: dein Vorname und die Maße deines Kellers.",
        "Configuremos tu bodega en unos pasos: tu nombre y las dimensiones de tu bodega.",
        "Configuriamo la tua cantina in pochi passi: il tuo nome e le dimensioni della cantina.",
        "Vamos configurar a sua adega em poucos passos: o seu nome e as dimensões da adega.",
        "数ステップでセラーを設定しましょう: お名前とセラーのサイズ。"),
    "Comment vous appelez-vous ?": ("What's your name?", "Wie heißt du?", "¿Cómo te llamas?", "Come ti chiami?", "Como se chama?", "お名前は？"),
    "Votre prénom sert à personnaliser l'application.": ("Your first name personalizes the app.", "Dein Vorname personalisiert die App.", "Tu nombre personaliza la aplicación.", "Il tuo nome personalizza l'app.", "O seu nome personaliza a aplicação.", "名前はアプリのパーソナライズに使われます。"),
    "Connecte-toi pour accéder à ta cave.": ("Sign in to access your cellar.", "Melde dich an, um auf deinen Weinkeller zuzugreifen.", "Inicia sesión para acceder a tu bodega.", "Accedi per accedere alla tua cantina.", "Inicie sessão para aceder à sua adega.", "サインインしてセラーにアクセス。"),
    "Vous": ("You", "Du", "Tú", "Tu", "Você", "あなた"),
    "Avec": ("With", "Mit", "Con", "Con", "Com", "同伴"),
    "Ici": ("Here", "Hier", "Aquí", "Qui", "Aqui", "ここ"),
    "Avec qui": ("With whom", "Mit wem", "Con quién", "Con chi", "Com quem", "誰と"),

    # --- Cellar dimensions ---
    "Dimensions": ("Dimensions", "Maße", "Dimensiones", "Dimensioni", "Dimensões", "サイズ"),
    "Dimensions de la cave": ("Cellar dimensions", "Kellermaße", "Dimensiones de la bodega", "Dimensioni della cantina", "Dimensões da adega", "セラーのサイズ"),
    "Reconfigurer ma cave": ("Reconfigure my cellar", "Weinkeller neu einrichten", "Reconfigurar mi bodega", "Riconfigura la cantina", "Reconfigurar a minha adega", "セラーを再設定"),
    "Choisissez un modèle du commerce ou ajustez les dimensions.": (
        "Pick a store model or adjust the dimensions.",
        "Wähle ein Handelsmodell oder passe die Maße an.",
        "Elige un modelo comercial o ajusta las dimensiones.",
        "Scegli un modello in commercio o regola le dimensioni.",
        "Escolha um modelo comercial ou ajuste as dimensões.",
        "市販モデルを選ぶか、サイズを調整してください。"),
    "Je saisis moi-même les dimensions": ("I'll enter the dimensions myself", "Ich gebe die Maße selbst ein", "Introduzco las dimensiones yo mismo", "Inserisco io le dimensioni", "Introduzo eu as dimensões", "自分でサイズを入力"),
    "Sur mesure": ("Custom", "Maßgeschneidert", "A medida", "Su misura", "Personalizado", "カスタム"),
    "Rechercher (marque, modèle)": ("Search (brand, model)", "Suchen (Marke, Modell)", "Buscar (marca, modelo)", "Cerca (marca, modello)", "Pesquisar (marca, modelo)", "検索（ブランド、モデル）"),
    "Rangées": ("Rows", "Reihen", "Filas", "File", "Filas", "行"),
    "Emplacements par rangée": ("Slots per row", "Plätze pro Reihe", "Huecos por fila", "Posti per fila", "Espaços por fila", "1行あたりの数"),
    "Les rangées sont étiquetées de A à Z (26 au maximum).": (
        "Rows are labeled A to Z (26 maximum).",
        "Reihen werden von A bis Z beschriftet (maximal 26).",
        "Las filas se etiquetan de la A a la Z (26 como máximo).",
        "Le file sono etichettate dalla A alla Z (massimo 26).",
        "As filas são identificadas de A a Z (máximo 26).",
        "行はAからZでラベル付けされます（最大26）。"),
    "Zones de température": ("Temperature zones", "Temperaturzonen", "Zonas de temperatura", "Zone di temperatura", "Zonas de temperatura", "温度ゾーン"),
    "Nombre de compartiments à températures indépendantes de votre cave.": (
        "Number of independently temperature-controlled compartments in your cellar.",
        "Anzahl der unabhängig temperierten Fächer deines Weinkellers.",
        "Número de compartimentos con temperatura independiente de tu bodega.",
        "Numero di scomparti a temperatura indipendente della tua cantina.",
        "Número de compartimentos com temperatura independente da sua adega.",
        "セラー内の独立温度管理コンパートメントの数。"),
    "Impossible de réduire la cave": ("Can't shrink the cellar", "Weinkeller kann nicht verkleinert werden", "No se puede reducir la bodega", "Impossibile ridurre la cantina", "Não é possível reduzir a adega", "セラーを縮小できません"),
    "Grille": ("Grid", "Raster", "Cuadrícula", "Griglia", "Grelha", "グリッド"),
    "Capacité totale": ("Total capacity", "Gesamtkapazität", "Capacidad total", "Capacità totale", "Capacidade total", "総容量"),

    # --- Dashboard ---
    "Votre cave": ("Your cellar", "Dein Weinkeller", "Tu bodega", "La tua cantina", "A sua adega", "あなたのセラー"),
    "Occupation": ("Occupancy", "Belegung", "Ocupación", "Occupazione", "Ocupação", "使用率"),
    "Total": ("Total", "Gesamt", "Total", "Totale", "Total", "合計"),
    "Vos bouteilles en cave": ("Your bottles in the cellar", "Deine Flaschen im Keller", "Tus botellas en la bodega", "Le tue bottiglie in cantina", "As suas garrafas na adega", "セラー内のボトル"),
    "Historique des entrées et sorties": ("History of entries and exits", "Verlauf der Ein- und Ausgänge", "Historial de entradas y salidas", "Storico di entrate e uscite", "Histórico de entradas e saídas", "入出庫の履歴"),
    "%lld bouteilles": ("%lld bottles", "%lld Flaschen", "%lld botellas", "%lld bottiglie", "%lld garrafas", "%lld 本"),
    "%lld emplacements": ("%lld slots", "%lld Plätze", "%lld huecos", "%lld posti", "%lld espaços", "%lld 区画"),
    "bouteille au total": ("bottle in total", "Flasche insgesamt", "botella en total", "bottiglia in totale", "garrafa no total", "本（合計）"),
    "bouteilles au total": ("bottles in total", "Flaschen insgesamt", "botellas en total", "bottiglie in totale", "garrafas no total", "本（合計）"),

    # --- Sharing / household ---
    "Partage": ("Sharing", "Teilen", "Compartir", "Condivisione", "Partilha", "共有"),
    "Membres du foyer": ("Household members", "Haushaltsmitglieder", "Miembros del hogar", "Membri della famiglia", "Membros do agregado", "世帯メンバー"),
    "Partagez votre cave avec les personnes de votre foyer. Chacun garde sa bibliothèque, ses notes et son journal ; seules les bouteilles en cave sont communes.": (
        "Share your cellar with the people in your household. Everyone keeps their own library, notes and journal; only the bottles in the cellar are shared.",
        "Teile deinen Weinkeller mit den Personen deines Haushalts. Jeder behält seine eigene Bibliothek, Notizen und Verlauf; nur die Flaschen im Keller sind gemeinsam.",
        "Comparte tu bodega con las personas de tu hogar. Cada uno conserva su biblioteca, notas y diario; solo las botellas de la bodega son comunes.",
        "Condividi la tua cantina con le persone della tua famiglia. Ognuno mantiene la propria libreria, note e diario; solo le bottiglie in cantina sono comuni.",
        "Partilhe a sua adega com as pessoas do seu agregado. Cada um mantém a sua biblioteca, notas e diário; apenas as garrafas na adega são comuns.",
        "セラーを世帯の人と共有しましょう。各自のライブラリ、メモ、履歴は個別のまま、セラー内のボトルだけが共有されます。"),
    "Inviter quelqu'un": ("Invite someone", "Jemanden einladen", "Invitar a alguien", "Invita qualcuno", "Convidar alguém", "誰かを招待"),
    "Invitation": ("Invitation", "Einladung", "Invitación", "Invito", "Convite", "招待"),
    "Invitations": ("Invitations", "Einladungen", "Invitaciones", "Inviti", "Convites", "招待"),
    "Code d'invitation": ("Invitation code", "Einladungscode", "Código de invitación", "Codice d'invito", "Código de convite", "招待コード"),
    "Générer un code d'invitation": ("Generate an invitation code", "Einladungscode erstellen", "Generar un código de invitación", "Genera un codice d'invito", "Gerar um código de convite", "招待コードを生成"),
    "Générer un nouveau code": ("Generate a new code", "Neuen Code erstellen", "Generar un nuevo código", "Genera un nuovo codice", "Gerar um novo código", "新しいコードを生成"),
    "Rejoindre un foyer": ("Join a household", "Einem Haushalt beitreten", "Unirse a un hogar", "Unisciti a una famiglia", "Juntar-se a um agregado", "世帯に参加"),
    "Rejoindre le foyer": ("Join the household", "Dem Haushalt beitreten", "Unirse al hogar", "Unisciti alla famiglia", "Juntar-se ao agregado", "世帯に参加"),
    "Rejoignez ce foyer pour partager la cave commune : les vins placés en cave sont visibles par tous ses membres. Votre bibliothèque, vos notes et votre journal restent personnels.": (
        "Join this household to share the common cellar: wines placed in the cellar are visible to all members. Your library, notes and journal stay personal.",
        "Tritt diesem Haushalt bei, um den gemeinsamen Weinkeller zu teilen: Weine im Keller sind für alle Mitglieder sichtbar. Deine Bibliothek, Notizen und dein Verlauf bleiben privat.",
        "Únete a este hogar para compartir la bodega común: los vinos colocados en la bodega son visibles para todos los miembros. Tu biblioteca, notas y diario siguen siendo personales.",
        "Unisciti a questa famiglia per condividere la cantina comune: i vini in cantina sono visibili a tutti i membri. La tua libreria, le note e il diario restano personali.",
        "Junte-se a este agregado para partilhar a adega comum: os vinhos colocados na adega são visíveis para todos os membros. A sua biblioteca, notas e diário permanecem pessoais.",
        "この世帯に参加して共有セラーを利用しましょう。セラー内のワインは全メンバーに表示されます。ライブラリ、メモ、履歴は個別のままです。"),
    "Vous avez rejoint le foyer": ("You joined the household", "Du bist dem Haushalt beigetreten", "Te has unido al hogar", "Ti sei unito alla famiglia", "Juntou-se ao agregado", "世帯に参加しました"),
    "Retirer ce membre ?": ("Remove this member?", "Dieses Mitglied entfernen?", "¿Quitar a este miembro?", "Rimuovere questo membro?", "Remover este membro?", "このメンバーを削除しますか？"),
    "Retirer %@": ("Remove %@", "%@ entfernen", "Quitar a %@", "Rimuovi %@", "Remover %@", "%@ を削除"),
    "%@ n'aura plus accès à la cave commune.": ("%@ will no longer have access to the shared cellar.", "%@ hat keinen Zugriff mehr auf den gemeinsamen Weinkeller.", "%@ ya no tendrá acceso a la bodega común.", "%@ non avrà più accesso alla cantina comune.", "%@ deixará de ter acesso à adega comum.", "%@ は共有セラーにアクセスできなくなります。"),
    "Révoquer ce code ?": ("Revoke this code?", "Diesen Code widerrufen?", "¿Revocar este código?", "Revocare questo codice?", "Revogar este código?", "このコードを取り消しますか？"),
    "Le code ne pourra plus être utilisé pour rejoindre le foyer.": ("The code can no longer be used to join the household.", "Der Code kann nicht mehr zum Beitritt verwendet werden.", "El código ya no podrá usarse para unirse al hogar.", "Il codice non potrà più essere usato per unirsi alla famiglia.", "O código deixará de poder ser usado para entrar no agregado.", "このコードは世帯への参加に使えなくなります。"),
    "Sans expiration": ("No expiration", "Ohne Ablauf", "Sin caducidad", "Senza scadenza", "Sem expiração", "有効期限なし"),
    "Valable jusqu'au %@": ("Valid until %@", "Gültig bis %@", "Válido hasta el %@", "Valido fino al %@", "Válido até %@", "%@ まで有効"),

    # --- Settings ---
    "Compte": ("Account", "Konto", "Cuenta", "Account", "Conta", "アカウント"),
    "Application": ("App", "App", "Aplicación", "App", "Aplicação", "アプリ"),
    "Données": ("Data", "Daten", "Datos", "Dati", "Dados", "データ"),
    "E-mail": ("Email", "E-Mail", "Correo", "E-mail", "E-mail", "メール"),
    "Confidentialité": ("Privacy", "Datenschutz", "Privacidad", "Privacy", "Privacidade", "プライバシー"),
    "Conditions d’utilisation": ("Terms of use", "Nutzungsbedingungen", "Términos de uso", "Termini d'uso", "Termos de utilização", "利用規約"),
    "Version & changelog": ("Version & changelog", "Version & Änderungen", "Versión y novedades", "Versione e novità", "Versão e novidades", "バージョンと変更履歴"),
    "Exporter mes données": ("Export my data", "Meine Daten exportieren", "Exportar mis datos", "Esporta i miei dati", "Exportar os meus dados", "データをエクスポート"),
    "Génère un fichier JSON contenant l'ensemble de tes vins, placements en cave, dégustations, recommandations, cadeaux et historique.": (
        "Generates a JSON file with all your wines, cellar placements, tastings, recommendations, gifts and history.",
        "Erzeugt eine JSON-Datei mit all deinen Weinen, Kellerplätzen, Verkostungen, Empfehlungen, Geschenken und dem Verlauf.",
        "Genera un archivo JSON con todos tus vinos, ubicaciones, catas, recomendaciones, regalos e historial.",
        "Genera un file JSON con tutti i tuoi vini, posizioni in cantina, degustazioni, consigli, regali e cronologia.",
        "Gera um ficheiro JSON com todos os seus vinhos, colocações, degustações, recomendações, ofertas e histórico.",
        "すべてのワイン、セラー配置、テイスティング、おすすめ、ギフト、履歴を含むJSONファイルを生成します。"),
    "Importer un fichier JSON": ("Import a JSON file", "JSON-Datei importieren", "Importar un archivo JSON", "Importa un file JSON", "Importar um ficheiro JSON", "JSONファイルをインポート"),
    "Confirmer l'import": ("Confirm import", "Import bestätigen", "Confirmar importación", "Conferma importazione", "Confirmar importação", "インポートを確認"),
    "L'import remplace l'ensemble de tes données par celles du fichier. Continuer ?": (
        "Importing replaces all your data with the file's. Continue?",
        "Der Import ersetzt all deine Daten durch die der Datei. Fortfahren?",
        "La importación reemplaza todos tus datos por los del archivo. ¿Continuar?",
        "L'importazione sostituisce tutti i tuoi dati con quelli del file. Continuare?",
        "A importação substitui todos os seus dados pelos do ficheiro. Continuar?",
        "インポートはすべてのデータをファイルの内容で置き換えます。続けますか？"),
    "Remplace l'intégralité de tes données par celles du fichier sélectionné. Cette action est irréversible.": (
        "Replaces all your data with the selected file's. This action is irreversible.",
        "Ersetzt all deine Daten durch die der ausgewählten Datei. Diese Aktion ist unumkehrbar.",
        "Reemplaza todos tus datos por los del archivo seleccionado. Esta acción es irreversible.",
        "Sostituisce tutti i tuoi dati con quelli del file selezionato. Questa azione è irreversibile.",
        "Substitui todos os seus dados pelos do ficheiro selecionado. Esta ação é irreversível.",
        "選択したファイルの内容ですべてのデータを置き換えます。この操作は取り消せません。"),
    "Abonnement": ("Subscription", "Abonnement", "Suscripción", "Abbonamento", "Subscrição", "サブスクリプション"),

    # --- Subscription / paywall ---
    "Restaurer mes achats": ("Restore purchases", "Käufe wiederherstellen", "Restaurar compras", "Ripristina acquisti", "Restaurar compras", "購入を復元"),
    "Scans épuisés ce mois-ci": ("Scans used up this month", "Scans diesen Monat aufgebraucht", "Escaneos agotados este mes", "Scansioni esaurite questo mese", "Digitalizações esgotadas este mês", "今月のスキャンを使い切りました"),
    "Votre quota du mois a été atteint. Passez en Premium pour profiter du scan illimité.": (
        "You've reached this month's quota. Go Premium for unlimited scanning.",
        "Dein Monatskontingent ist erreicht. Wechsle zu Premium für unbegrenztes Scannen.",
        "Has alcanzado el cupo del mes. Pásate a Premium para escanear sin límite.",
        "Hai raggiunto la quota del mese. Passa a Premium per scansioni illimitate.",
        "Atingiu a quota do mês. Mude para Premium para digitalizações ilimitadas.",
        "今月の上限に達しました。Premiumで無制限にスキャン。"),
    "Le scan d’étiquette reconnaît vos bouteilles et enrichit leur fiche. Passez en Premium pour scanner sans limite.": (
        "Label scanning recognizes your bottles and fills in their details. Go Premium to scan without limits.",
        "Die Etikett-Erkennung erkennt deine Flaschen und füllt ihre Details aus. Wechsle zu Premium für unbegrenztes Scannen.",
        "El escaneo de etiquetas reconoce tus botellas y completa su ficha. Pásate a Premium para escanear sin límite.",
        "La scansione dell'etichetta riconosce le bottiglie e ne compila la scheda. Passa a Premium per scansioni illimitate.",
        "A digitalização de rótulos reconhece as garrafas e preenche a ficha. Mude para Premium para digitalizar sem limites.",
        "ラベルスキャンはボトルを認識し情報を自動入力します。Premiumで無制限にスキャン。"),
    "Les offres ne sont pas disponibles pour le moment.": ("Offers aren't available right now.", "Angebote sind derzeit nicht verfügbar.", "Las ofertas no están disponibles ahora mismo.", "Le offerte non sono disponibili al momento.", "As ofertas não estão disponíveis de momento.", "現在オファーは利用できません。"),
    "L’abonnement se renouvelle automatiquement sauf résiliation au moins 24 heures avant la fin de la période en cours. La gestion et la résiliation se font dans les réglages du compte App Store.": (
        "The subscription renews automatically unless canceled at least 24 hours before the end of the current period. Manage and cancel it in your App Store account settings.",
        "Das Abonnement verlängert sich automatisch, sofern es nicht mindestens 24 Stunden vor Ende des laufenden Zeitraums gekündigt wird. Verwaltung und Kündigung erfolgen in den App-Store-Kontoeinstellungen.",
        "La suscripción se renueva automáticamente salvo cancelación al menos 24 horas antes del fin del período actual. La gestión y cancelación se hacen en los ajustes de la cuenta de App Store.",
        "L'abbonamento si rinnova automaticamente salvo disdetta almeno 24 ore prima della fine del periodo in corso. Gestione e disdetta si effettuano nelle impostazioni dell'account App Store.",
        "A subscrição renova-se automaticamente salvo cancelamento pelo menos 24 horas antes do fim do período atual. A gestão e o cancelamento fazem-se nas definições da conta App Store.",
        "サブスクリプションは、現在の期間終了の24時間以上前に解約しない限り自動更新されます。管理と解約はApp Storeアカウント設定で行います。"),

    # --- Errors / misc ---
    "Erreur": ("Error", "Fehler", "Error", "Errore", "Erro", "エラー"),
    "Une erreur est survenue": ("Something went wrong", "Ein Fehler ist aufgetreten", "Se produjo un error", "Si è verificato un errore", "Ocorreu um erro", "エラーが発生しました"),
    "Connexion impossible": ("Sign-in failed", "Anmeldung fehlgeschlagen", "No se pudo iniciar sesión", "Accesso non riuscito", "Não foi possível iniciar sessão", "サインインできませんでした"),
    "Achat impossible": ("Purchase failed", "Kauf fehlgeschlagen", "No se pudo completar la compra", "Acquisto non riuscito", "Não foi possível concluir a compra", "購入できませんでした"),
    "Cette action est irréversible. Le vin sera supprimé de votre collection, de la cave et de toutes les données associées.": (
        "This action is irreversible. The wine will be removed from your collection, the cellar and all associated data.",
        "Diese Aktion ist unumkehrbar. Der Wein wird aus deiner Sammlung, dem Keller und allen zugehörigen Daten entfernt.",
        "Esta acción es irreversible. El vino se eliminará de tu colección, la bodega y todos los datos asociados.",
        "Questa azione è irreversibile. Il vino sarà rimosso dalla tua collezione, dalla cantina e da tutti i dati associati.",
        "Esta ação é irreversível. O vinho será removido da sua coleção, da adega e de todos os dados associados.",
        "この操作は取り消せません。ワインはコレクション、セラー、関連するすべてのデータから削除されます。"),
    "Supprimer ce vin ?": ("Delete this wine?", "Diesen Wein löschen?", "¿Eliminar este vino?", "Eliminare questo vino?", "Eliminar este vinho?", "このワインを削除しますか？"),
    "Mise à jour requise": ("Update required", "Aktualisierung erforderlich", "Actualización necesaria", "Aggiornamento richiesto", "Atualização necessária", "アップデートが必要です"),
    "Cette version de Vinarium n'est plus compatible avec le serveur. La dernière version est disponible sur l'App Store.": (
        "This version of Vinarium is no longer compatible with the server. The latest version is available on the App Store.",
        "Diese Version von Vinarium ist nicht mehr mit dem Server kompatibel. Die neueste Version ist im App Store verfügbar.",
        "Esta versión de Vinarium ya no es compatible con el servidor. La última versión está disponible en la App Store.",
        "Questa versione di Vinarium non è più compatibile con il server. L'ultima versione è disponibile sull'App Store.",
        "Esta versão do Vinarium já não é compatível com o servidor. A versão mais recente está disponível na App Store.",
        "このバージョンのVinariumはサーバーと互換性がありません。最新版はApp Storeで入手できます。"),

    # --- Recommendation / gift ---
    "Pourquoi ce conseil ?": ("Why this recommendation?", "Warum diese Empfehlung?", "¿Por qué esta recomendación?", "Perché questo consiglio?", "Porquê esta recomendação?", "このおすすめの理由は？"),
    "Destinataire": ("Recipient", "Empfänger", "Destinatario", "Destinatario", "Destinatário", "受取人"),
    "Lieu de découverte": ("Where discovered", "Ort der Entdeckung", "Lugar del descubrimiento", "Luogo della scoperta", "Local da descoberta", "発見場所"),
    "Lieux sur le plan": ("Places on the map", "Orte auf der Karte", "Lugares en el mapa", "Luoghi sulla mappa", "Locais no mapa", "地図上の場所"),
    "Ajouter un lieu": ("Add a place", "Ort hinzufügen", "Añadir un lugar", "Aggiungi un luogo", "Adicionar um local", "場所を追加"),
    "Ajuster le lieu": ("Adjust the place", "Ort anpassen", "Ajustar el lugar", "Regola il luogo", "Ajustar o local", "場所を調整"),

    "Consommation": ("Consumption", "Verzehr", "Consumo", "Consumo", "Consumo", "消費"),
    "Conseil": ("Recommendation", "Empfehlung", "Recomendación", "Consiglio", "Recomendação", "おすすめ"),
    "Cadeau": ("Gift", "Geschenk", "Regalo", "Regalo", "Oferta", "ギフト"),
    "Vin conseillé": ("Recommended wine", "Empfohlener Wein", "Vino recomendado", "Vino consigliato", "Vinho recomendado", "おすすめワイン"),
    "Tous vos vins ajoutés": ("All the wines you've added", "Alle deine hinzugefügten Weine", "Todos los vinos que has añadido", "Tutti i vini che hai aggiunto", "Todos os vinhos que adicionou", "追加したすべてのワイン"),
    "Vins qu'on vous a offerts": ("Wines you were given", "Dir geschenkte Weine", "Vinos que te han regalado", "Vini che ti sono stati regalati", "Vinhos que lhe ofereceram", "贈られたワイン"),
    "Vins recommandés par vos proches": ("Wines recommended by people close to you", "Von deinen Nächsten empfohlene Weine", "Vinos recomendados por tus allegados", "Vini consigliati dai tuoi cari", "Vinhos recomendados pelos seus próximos", "身近な人からのおすすめワイン"),
    "Note : %lld sur %lld": ("Rating: %lld out of %lld", "Bewertung: %lld von %lld", "Nota: %lld de %lld", "Voto: %lld su %lld", "Nota: %lld de %lld", "評価: %lld 中 %lld"),

    # --- Toggles / hints ---
    "Un cœur pour vos coups de cœur, des étoiles pour la note — les deux sont indépendants.": (
        "A heart for your favorites, stars for the rating. The two are independent.",
        "Ein Herz für deine Favoriten, Sterne für die Bewertung. Beide sind unabhängig.",
        "Un corazón para tus favoritos, estrellas para la nota. Ambos son independientes.",
        "Un cuore per i preferiti, stelle per il voto. I due sono indipendenti.",
        "Um coração para os favoritos, estrelas para a nota. Os dois são independentes.",
        "お気に入りはハート、評価は星。両者は独立しています。"),
    "En attente": ("Pending", "Ausstehend", "Pendiente", "In attesa", "Pendente", "保留中"),
}


def main():
    data = json.loads(CATALOG.read_text())
    strings = data["strings"]
    filled = 0
    missing = []
    for key, entry in strings.items():
        if key not in T:
            missing.append(key)
            continue
        values = T[key]
        locs = entry.setdefault("localizations", {})
        for lang, value in zip(LANGS, values):
            locs[lang] = {"stringUnit": {"state": "translated", "value": value}}
        entry.pop("shouldTranslate", None)
        filled += 1
    CATALOG.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
    print(f"Filled {filled} keys across {len(LANGS)} languages.")
    print(f"Left as French fallback ({len(missing)}): "
          + ", ".join(repr(m) for m in sorted(missing)))


if __name__ == "__main__":
    main()
