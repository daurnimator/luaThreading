all: call_wrapper.so

call_wrapper.so: call_wrapper.c
	$(CC) --shared -fPIC --pedantic -o $@ $<

clean:
	rm call_wrapper.so
