package app;

final class SearchServiceImpl implements SearchService {
    @Override
    public String find(String query) {
        return "hit:" + query;
    }
}
