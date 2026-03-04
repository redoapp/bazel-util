def get_versioned_facts(facts, version):
    facts = facts.get(_FACTS_KEY)
    if not facts or facts["_version"] != version:
        return
    return {key: value for key, value in facts.items() if key != "_version"}

def create_versioned_facts(version, facts):
    return {_FACTS_KEY: facts | {"_version": version}}

_FACTS_KEY = "_"
