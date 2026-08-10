from uuid import UUID
from pydantic import BaseModel

class MatchmakingRequest(BaseModel):
    profile1_id: UUID
    profile2_id: UUID

class AshtakootScore(BaseModel):
    varna: float
    vashya: float
    tara: float
    yoni: float
    graha_maitri: float
    gana: float
    bhakoot: float
    nadi: float
    total: float

class MatchmakingResponse(BaseModel):
    profile1_id: UUID
    profile2_id: UUID
    ashtakoot: AshtakootScore
